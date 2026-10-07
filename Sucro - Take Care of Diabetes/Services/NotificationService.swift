//
//  NotificationService.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//
//  The only type that talks to UNUserNotificationCenter. Every request uses
//  a stable identifier, so scheduling the same thing again replaces it
//  instead of stacking duplicates.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationService: NSObject {
    static let shared = NotificationService()

    enum Identifier {
        static let glucosePrefix = "alert.glucose."
        static let staleData = "alert.cgmStale"
        static let reminderPrefix = "reminder."

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
            print("Notification authorization error: \(error.localizedDescription)")
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
            content.title = "Urgent Low Glucose"
            content.body = "Glucose is \(formatted). Eat 15g of fast-acting carbs now and recheck in 15 minutes."
        case .low:
            content.title = "Low Glucose"
            content.body = "Glucose is \(formatted). Eat 15g of fast-acting carbs and recheck in 15 minutes."
        case .urgentHigh:
            content.title = "High Glucose"
            content.body = "Glucose is \(formatted). Check for ketones."
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

    // MARK: - Missing CGM data

    /// Schedules (or replaces) the "no recent readings" warning for `date`.
    /// A date in the past delivers it now.
    func scheduleStaleDataAlert(at date: Date, lastReading: Date) {
        guard notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "No Recent Glucose Readings"
        let time = lastReading.formatted(date: .omitted, time: .shortened)
        content.body = "The last reading was at \(time). Check that your CGM sensor is working."
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let interval = date.timeIntervalSinceNow
        let trigger = interval > 1 ? UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false) : nil
        add(UNNotificationRequest(identifier: Identifier.staleData, content: content, trigger: trigger))
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
                print("Failed to schedule \(identifier): \(error.localizedDescription)")
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
