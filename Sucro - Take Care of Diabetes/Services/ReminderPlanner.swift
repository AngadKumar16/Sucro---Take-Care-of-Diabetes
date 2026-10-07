//
//  ReminderPlanner.swift
//  Sucro - Take Care of Diabetes
//

import Foundation

/// What reminders are due, given the latest logged events. Pure.
nonisolated enum ReminderPlanner {
    /// How long after a rapid-acting dose to suggest checking glucose.
    static let glucoseCheckDelay: TimeInterval = 2 * 3600

    struct SiteChangeInfo: Sendable {
        let date: Date
        let rotationDays: Int
    }

    static func plan(lastSiteChange: SiteChangeInfo?, lastRapidDose: Date?) -> [PlannedReminder] {
        var reminders: [PlannedReminder] = []

        if let change = lastSiteChange,
           let due = Calendar.current.date(byAdding: .day, value: change.rotationDays, to: change.date) {
            reminders.append(PlannedReminder(
                id: "reminder.siteChange.\(Int(change.date.timeIntervalSince1970))",
                title: "Site Change Due",
                time: due,
                kind: .siteChange,
                notes: "Your infusion site is \(change.rotationDays) days old. Time to change it."
            ))
        }

        if let dose = lastRapidDose {
            reminders.append(PlannedReminder(
                id: "reminder.glucoseCheck.\(Int(dose.timeIntervalSince1970))",
                title: "Check Glucose",
                time: dose.addingTimeInterval(glucoseCheckDelay),
                kind: .glucoseCheck,
                notes: "It's been 2 hours since your last dose. Check your glucose."
            ))
        }

        return reminders
    }

    struct PlannedReminder: Equatable, Sendable {
        let id: String
        let title: String
        let time: Date
        let kind: Kind
        let notes: String

        enum Kind: Sendable { case siteChange, glucoseCheck }
    }
}
