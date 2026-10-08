//
//  ReminderService.swift
//  Sucro - Take Care of Diabetes
//
//  Works out the upcoming reminders shown in Today's Plan from the logged
//  data, and keeps their notifications in sync through NotificationService.
//
//  Each reminder belongs to a specific event (the site change at 9:14,
//  the dose at 12:30), so its id is stable. Refreshing as often as the UI
//  likes never duplicates or reschedules anything, and snoozes and
//  completions stick to that occurrence.
//

import Foundation
import CoreData

@MainActor
@Observable
final class ReminderService {
    static let shared = ReminderService()

    private(set) var upcomingReminders: [Reminder] = []

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let notifications: NotificationService
    @ObservationIgnored private let dataService = DataService.shared

    private enum Key {
        static let snoozed = "reminders.snoozedUntil"
        static let completed = "reminders.completed"
    }

    init(defaults: UserDefaults = .standard, notifications: NotificationService? = nil) {
        self.defaults = defaults
        self.notifications = notifications ?? .shared
    }

    /// Recomputes reminders from the store and syncs notifications.
    func refresh(context: NSManagedObjectContext, now: Date = Date()) {
        let siteChange = dataService.fetchLastSiteChange(context: context).flatMap { change -> ReminderPlanner.SiteChangeInfo? in
            guard let date = change.timestamp else { return nil }
            let days = SiteLocation(stored: change.location)?.rotationDays ?? 3
            return ReminderPlanner.SiteChangeInfo(date: date, rotationDays: days)
        }
        let lastDose = dataService.fetchLastRapidActingDose(
            context: context,
            since: now.addingTimeInterval(-ReminderPlanner.glucoseCheckDelay)
        )?.timestamp

        let planned = ReminderPlanner.plan(lastSiteChange: siteChange, lastRapidDose: lastDose)
        apply(planned, now: now)
    }

    /// Pushes a reminder back by `minutes` from when it was due, or from now
    /// if it's already due.
    func snooze(_ reminder: Reminder, minutes: Int, now: Date = Date()) {
        var snoozed = snoozedUntil
        snoozed[reminder.id] = max(reminder.time, now).addingTimeInterval(TimeInterval(minutes * 60))
        snoozedUntil = snoozed

        upcomingReminders = upcomingReminders
            .map { $0.id == reminder.id ? reminder.rescheduled(to: snoozed[reminder.id]!) : $0 }
            .sorted { $0.time < $1.time }
        notifications.syncReminders(upcomingReminders)
    }

    func complete(_ reminder: Reminder) {
        var done = completed
        done.insert(reminder.id)
        completed = done

        upcomingReminders.removeAll { $0.id == reminder.id }
        notifications.cancelReminder(id: reminder.id)
    }

    /// Forgets snoozes and completions. Used after Clear All Data.
    func reset() {
        defaults.removeObject(forKey: Key.snoozed)
        defaults.removeObject(forKey: Key.completed)
        upcomingReminders = []
        notifications.syncReminders([])
    }

    // MARK: - Private

    private func apply(_ planned: [ReminderPlanner.PlannedReminder], now: Date) {
        let ids = Set(planned.map(\.id))
        // Drop bookkeeping for occurrences that no longer exist.
        snoozedUntil = snoozedUntil.filter { ids.contains($0.key) }
        completed = completed.intersection(ids)

        upcomingReminders = planned
            .filter { !completed.contains($0.id) }
            .map { plan in
                Reminder(
                    id: plan.id,
                    title: plan.title,
                    time: snoozedUntil[plan.id] ?? plan.time,
                    type: plan.kind == .siteChange ? .siteChange : .glucoseCheck,
                    notes: plan.notes
                )
            }
            // Past-due site changes are shown by the Home banner instead.
            .filter { $0.time > now }
            .sorted { $0.time < $1.time }

        notifications.syncReminders(upcomingReminders)
    }

    private var snoozedUntil: [String: Date] {
        get { defaults.dictionary(forKey: Key.snoozed) as? [String: Date] ?? [:] }
        set { defaults.set(newValue, forKey: Key.snoozed) }
    }

    private var completed: Set<String> {
        get { Set(defaults.stringArray(forKey: Key.completed) ?? []) }
        set { defaults.set(Array(newValue), forKey: Key.completed) }
    }
}

private extension Reminder {
    func rescheduled(to time: Date) -> Reminder {
        Reminder(id: id, title: title, time: time, type: type, notes: notes)
    }
}
