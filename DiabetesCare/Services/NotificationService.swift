//
//  NotificationService.swift
//  DiabetesCare
//
//  Created by Angad Kumar on 3/12/26.
//
//  The only type that talks to UNUserNotificationCenter. Every request uses
//  a stable identifier, so scheduling the same thing again replaces it
//  instead of stacking duplicates.
//

import Foundation
import OSLog
import UserNotifications

@MainActor
final class NotificationService: NSObject {
    static let shared = NotificationService()

    enum Identifier {
        static let glucosePrefix = "alert.glucose."
        static let staleData = "alert.cgmStale"
        static let reminderPrefix = "reminder."
        static let lowRecheck = "alert.lowRecheck"
        static let familyPrefix = "family."

        static func glucose(_ kind: GlucoseAlertKind) -> String { glucosePrefix + kind.rawValue }
    }

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
    }

    /// Respects the Notifications switch in Settings.
    private var notificationsEnabled: Bool {
        SettingsStore.shared.notificationsEnabled
    }

    // MARK: - Authorization

    /// Shows the system permission prompt the first time; does nothing after
    /// the user has answered.
    func requestAuthorizationIfNeeded() async {
        guard await center.notificationSettings().authorizationStatus == .notDetermined else { return }
        do {
            try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            Log.notifications.error("Notification authorization error: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Glucose alerts

    /// Sends a low or high glucose alert right away. Each kind has one
    /// identifier, so a newer alert replaces the older one on screen.
    ///
    /// These are time-sensitive, not critical: critical alerts need an
    /// entitlement Apple grants on request, so they can't break through
    /// Silent mode or Focus yet.
    func deliverGlucoseAlert(kind: GlucoseAlertKind, mgdl: Double) {
        guard notificationsEnabled else { return }
        let formatted = SettingsStore.shared.formattedGlucose(mgdl)

        let content = UNMutableNotificationContent()
        switch kind {
        case .urgentLow:
            content.title = String(localized: "Urgent Low Glucose")
            content.body = String(localized: "Glucose is \(formatted). Eat 15g of fast-acting carbs now and recheck in 15 minutes.")
        case .low:
            content.title = String(localized: "Low Glucose")
            content.body = String(localized: "Glucose is \(formatted). Eat 15g of fast-acting carbs and recheck in 15 minutes.")
        case .urgentHigh:
            content.title = String(localized: "High Glucose")
            content.body = String(localized: "Glucose is \(formatted). Check for ketones.")
        }
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        // Clear any other glucose alert so a stale "low" doesn't sit next to
        // a new "high".
        let others = [GlucoseAlertKind.urgentLow, .low, .urgentHigh]
            .filter { $0 != kind }
            .map(Identifier.glucose)
        center.removeDeliveredNotifications(withIdentifiers: others)

        add(UNNotificationRequest(identifier: Identifier.glucose(kind), content: content, trigger: nil))
    }

    // MARK: - Family

    /// An alert about someone this phone follows. One identifier per person
    /// and kind, so a newer alert replaces the older one.
    func deliverFamilyAlert(_ alert: CaregiverAlert, name: String, personID: String) {
        guard notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        let id: String
        switch alert {
        case .glucose(let kind, let mgdl):
            let formatted = SettingsStore.shared.formattedGlucose(mgdl)
            switch kind {
            case .urgentLow:
                content.title = String(localized: "\(name): Urgent Low")
                content.body = String(localized: "Glucose is \(formatted). Check on \(name) now.")
            case .low:
                content.title = String(localized: "\(name): Low")
                content.body = String(localized: "Glucose is \(formatted).")
            case .urgentHigh:
                content.title = String(localized: "\(name): High")
                content.body = String(localized: "Glucose is \(formatted). Ketones may need checking.")
            }
            id = "\(Identifier.familyPrefix)\(personID).glucose"
        case .noRecentData(let lastReading):
            content.title = String(localized: "\(name): No Recent Readings")
            content.body = String(localized: "The last reading was at \(lastReading.formatted(date: .omitted, time: .shortened)).")
            id = "\(Identifier.familyPrefix)\(personID).stale"
        case .helpRequested(let request):
            content.title = String(localized: "\(name) Asked for Help")
            if let mgdl = request.mgdl {
                content.body = String(localized: "Sent at \(request.sentAt.formatted(date: .omitted, time: .shortened)). Last glucose \(SettingsStore.shared.formattedGlucose(mgdl)).")
            } else {
                content.body = String(localized: "Sent at \(request.sentAt.formatted(date: .omitted, time: .shortened)).")
            }
            id = "\(Identifier.familyPrefix)\(personID).help"
        }
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        add(UNNotificationRequest(identifier: id, content: content, trigger: nil))
    }

    // MARK: - Missing CGM data

    /// Schedules (or replaces) the "no recent readings" warning for `date`.
    /// A date in the past delivers it now.
    func scheduleStaleDataAlert(at date: Date, lastReading: Date) {
        guard notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "No Recent Glucose Readings")
        let time = lastReading.formatted(date: .omitted, time: .shortened)
        content.body = String(localized: "The last reading was at \(time). Check that your CGM sensor is working.")
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let interval = date.timeIntervalSinceNow
        let trigger = interval > 1 ? UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false) : nil
        add(UNNotificationRequest(identifier: Identifier.staleData, content: content, trigger: trigger))
    }

    /// The "check again" nudge 15 minutes after treating a low.
    func scheduleLowRecheck(at date: Date, grams: Double) {
        guard notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Check Your Glucose Again")
        content.body = String(localized: "It's been 15 minutes since you had \(grams.formatted(.number.precision(.fractionLength(0)))) g of carbs for a low.")
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSinceNow), repeats: false)
        add(UNNotificationRequest(identifier: Identifier.lowRecheck, content: content, trigger: trigger))
    }

    func cancelStaleDataAlert() {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.staleData])
    }

    // MARK: - Reminders

    /// Makes the pending reminder notifications match `reminders` exactly:
    /// adds or replaces the ones listed and removes any others.
    func syncReminders(_ reminders: [Reminder]) {
        let wanted = notificationsEnabled ? reminders.filter { $0.time > .now } : []
        let wantedIDs = Set(wanted.map(\.id))

        Task {
            let obsolete = await center.pendingNotificationRequests()
                .map(\.identifier)
                .filter { $0.hasPrefix(Identifier.reminderPrefix) && !wantedIDs.contains($0) }
            center.removePendingNotificationRequests(withIdentifiers: obsolete)
        }

        for reminder in wanted {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.notes ?? ""
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, reminder.time.timeIntervalSinceNow), repeats: false)
            add(UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger))
        }
    }

    func cancelReminder(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    // MARK: - Everything

    /// Removes every pending and delivered notification from this app. Used
    /// when notifications are switched off and after Clear All Data.
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    private func add(_ request: UNNotificationRequest) {
        let identifier = request.identifier
        Task {
            do {
                try await center.add(request)
            } catch {
                Log.notifications.error("Failed to schedule \(identifier, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Show alerts as banners even while the app is open.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}
