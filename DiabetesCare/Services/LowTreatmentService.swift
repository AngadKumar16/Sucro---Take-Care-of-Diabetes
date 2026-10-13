//
//  LowTreatmentService.swift
//  DiabetesCare
//
//  Treating a low, wherever it starts (Today, Get Help, a widget, Siri):
//  log the fast-acting carbs, schedule the 15-minute recheck, and show the
//  countdown as a Live Activity on the Lock Screen and Dynamic Island.
//

import ActivityKit
import CoreData
import Foundation
import OSLog

@MainActor
enum LowTreatmentService {
    static let recheckAfter: TimeInterval = 15 * 60

    /// Logs the carbs and starts the recheck. Returns when to check again.
    @discardableResult
    static func logFastCarbs(grams: Double, context: NSManagedObjectContext, now: Date = Date()) -> Date {
        let entry = CarbEntry(context: context)
        entry.id = UUID()
        entry.grams = grams
        entry.mealType = MealType.snack.rawValue
        entry.foodItems = "Fast-acting carbs"
        entry.notes = "Treating a low"
        entry.timestamp = now
        do {
            try context.save()
        } catch {
            context.rollback()
            Log.data.error("Couldn't save fast carbs: \(error.localizedDescription, privacy: .public)")
        }
        HealthKitManager.shared.saveCarbohydrateIntake(grams, timestamp: now)

        let recheck = now.addingTimeInterval(recheckAfter)
        NotificationService.shared.scheduleLowRecheck(at: recheck, grams: grams)
        LowTreatmentActivity.start(grams: grams, recheckAt: recheck, settings: .shared)
        AppGroup.defaults.set(recheck, forKey: "glance.lowRecheckAt")
        GlanceWriter.shared.scheduleUpdate()
        return recheck
    }

    /// The recheck time of a treatment still in progress, if any.
    static var pendingRecheck: Date? {
        guard let date = AppGroup.defaults.object(forKey: "glance.lowRecheckAt") as? Date,
              Date().timeIntervalSince(date) < 45 * 60 else { return nil }
        return date
    }

    static func clear() {
        AppGroup.defaults.removeObject(forKey: "glance.lowRecheckAt")
    }
}

/// Drives the Live Activity. Does nothing where Live Activities are off.
@MainActor
enum LowTreatmentActivity {
    private static var current: Activity<LowTreatmentAttributes>? {
        Activity<LowTreatmentAttributes>.activities.first
    }

    static func start(grams: Double, recheckAt: Date, settings: SettingsStore) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        // One treatment at a time: a second carb log replaces the first.
        Task {
            for activity in Activity<LowTreatmentAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            let attributes = LowTreatmentAttributes(grams: grams, startedAt: Date(), unit: settings.glucoseUnit, targetLow: settings.targetLow)
            let state = LowTreatmentAttributes.ContentState(phase: .waiting, recheckAt: recheckAt, latestMgdl: nil, latestAt: nil)
            do {
                _ = try Activity.request(
                    attributes: attributes,
                    content: ActivityContent(state: state, staleDate: recheckAt.addingTimeInterval(30 * 60), relevanceScore: 100)
                )
            } catch {
                Log.notifications.error("Live Activity failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Moves the activity along as readings come in: shows the newest one,
    /// says when it's time to recheck, and ends once back in range.
    static func update(latest: GlucoseSample?, now: Date = Date()) {
        guard let activity = current else { return }
        let attributes = activity.attributes
        var state = activity.content.state
        if let latest, latest.date > attributes.startedAt {
            state.latestMgdl = latest.mgdl
            state.latestAt = latest.date
        }
        if let mgdl = state.latestMgdl, mgdl >= attributes.targetLow, let at = state.latestAt, at >= state.recheckAt.addingTimeInterval(-5 * 60) {
            state.phase = .recovered
        } else {
            state.phase = now >= state.recheckAt ? .recheck : .waiting
        }
        guard state != activity.content.state else { return }
        Task {
            let content = ActivityContent(state: state, staleDate: now.addingTimeInterval(30 * 60))
            if state.phase == .recovered {
                LowTreatmentService.clear()
                await activity.end(content, dismissalPolicy: .after(now.addingTimeInterval(10 * 60)))
            } else {
                await activity.update(content)
            }
            // Ends on its own an hour in, so a forgotten one doesn't linger.
            if now.timeIntervalSince(attributes.startedAt) > 3600 {
                await activity.end(content, dismissalPolicy: .immediate)
            }
        }
    }
}
