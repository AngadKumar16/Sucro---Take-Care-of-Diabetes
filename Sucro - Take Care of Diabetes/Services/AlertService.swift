//
//  AlertService.swift
//  Sucro - Take Care of Diabetes
//
//  Decides when to warn about glucose and missing CGM data, and keeps the
//  bookkeeping that stops the same event from notifying over and over.
//
//  `GlucoseAlertPolicy` is pure so it can be unit tested. `AlertService`
//  feeds it data from Core Data, persists its state, and talks to
//  `NotificationService`.
//

import Foundation
import CoreData

@MainActor
final class AlertService {
    static let shared = AlertService()

    private let defaults: UserDefaults
    private let notifications: NotificationService
    private let policy = GlucoseAlertPolicy()
    private static let stateKey = "alerts.state"

    init(defaults: UserDefaults = .standard, notifications: NotificationService? = nil) {
        self.defaults = defaults
        self.notifications = notifications ?? .shared
    }

    private(set) var state: AlertState {
        get {
            guard let data = defaults.data(forKey: Self.stateKey),
                  let state = try? JSONDecoder().decode(AlertState.self, from: data) else { return AlertState() }
            return state
        }
        set {
            defaults.set(try? JSONEncoder().encode(newValue), forKey: Self.stateKey)
        }
    }

    /// Re-evaluates alerts against the stored data: sends any notification
    /// that is due, (re)schedules the missing-data warning, and returns what
    /// the Home banner should show. Safe to call as often as you like.
    @discardableResult
    func evaluate(context: NSManagedObjectContext, settings: SettingsStore? = nil, now: Date = Date()) -> AlertType? {
        let settings = settings ?? .shared
        let samples = recentSamples(context: context, now: now)
        let latest = samples.max { $0.date < $1.date }

        // Glucose thresholds
        let decision = policy.evaluateGlucose(latest: latest, thresholds: settings.thresholds, state: state, now: now)
        var newState = decision.state
        if let kind = decision.notify, let latest {
            notifications.deliverGlucoseAlert(kind: kind, mgdl: latest.mgdl)
        }

        // Missing CGM data
        // A warning is scheduled for when the gap will start, so it fires even
        // if the app isn't open. If the gap already started and nothing was
        // scheduled for this reading (say it was logged late), warn now.
        var staleMinutes: Int?
        if let deadline = policy.staleDeadline(for: samples), let latest {
            if deadline > now {
                notifications.scheduleStaleDataAlert(at: deadline, lastReading: latest.date)
                newState.staleNotifiedForReading = latest.date
            } else {
                staleMinutes = Int(now.timeIntervalSince(latest.date) / 60)
                if newState.staleNotifiedForReading != latest.date {
                    newState.staleNotifiedForReading = latest.date
                    notifications.scheduleStaleDataAlert(at: now, lastReading: latest.date)
                }
            }
        } else {
            notifications.cancelStaleDataAlert()
        }

        state = newState
        return banner(latest: latest, staleMinutes: staleMinutes, context: context, settings: settings, now: now)
    }

    /// Forgets all alert history. Used after Clear All Data.
    func reset() {
        defaults.removeObject(forKey: Self.stateKey)
        notifications.cancelStaleDataAlert()
    }

    func handleAlertAction(_ alert: AlertType) -> AlertAction {
        switch alert {
        case .lowGlucose: return .showAddCarb
        case .highGlucose: return .showKetoneInfo
        case .cgmDataStale: return .showDeviceTroubleshooting
        case .siteChangeOverdue: return .showSiteChange
        }
    }

    // MARK: - Private

    private func banner(latest: GlucoseSample?, staleMinutes: Int?, context: NSManagedObjectContext, settings: SettingsStore, now: Date) -> AlertType? {
        if let latest, now.timeIntervalSince(latest.date) <= policy.bannerFreshness {
            let zone = settings.zone(for: latest.mgdl)
            if zone.isLow { return .lowGlucose(latest.mgdl) }
            if zone == .urgentHigh { return .highGlucose(latest.mgdl) }
        }

        if let staleMinutes {
            return .cgmDataStale(minutes: staleMinutes)
        }

        if let lastChange = DataService.shared.fetchLastSiteChange(context: context),
           let changed = lastChange.timestamp {
            let rotationDays = SiteLocation(stored: lastChange.location)?.rotationDays ?? 3
            let days = Calendar.current.dateComponents([.day], from: changed, to: now).day ?? 0
            if days >= rotationDays {
                return .siteChangeOverdue(days)
            }
        }
        return nil
    }

    /// The latest reading plus the ones logged in the hour before it, enough
    /// for the CGM-stream check however long ago that was.
    private func recentSamples(context: NSManagedObjectContext, now: Date) -> [GlucoseSample] {
        let request: NSFetchRequest<GlucoseReading> = GlucoseReading.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp <= %@", now as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReading.timestamp, ascending: false)]
        request.fetchLimit = 30
        let samples = ((try? context.fetch(request)) ?? []).compactMap(\.sample)
        guard let latest = samples.first else { return [] }
        return samples.filter { latest.date.timeIntervalSince($0.date) <= 3600 }
    }
}
