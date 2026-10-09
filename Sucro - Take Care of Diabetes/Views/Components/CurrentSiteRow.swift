//
//  CurrentSiteRow.swift
//  Sucro - Take Care of Diabetes
//
//  The current infusion site inside `SiteSnapshotView`.
//

import SwiftUI

struct CurrentSiteRow: View {
    /// Observed so editing the site change (from Log) redraws it.
    @ObservedObject var siteChange: SiteChange
    let now: Date

    var body: some View {
        let changed = siteChange.timestamp ?? now
        let location = SiteLocation(stored: siteChange.location)
        let name = siteChange.location ?? "Unknown site"
        let due = Calendar.current.date(byAdding: .day, value: location?.rotationDays ?? 3, to: changed) ?? changed
        let isOverdue = now >= due

        return VStack(alignment: .leading, spacing: 2) {
            Text(location?.spokenName ?? name)
                .font(.system(.headline, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.vermilion)
            Text("Inserted \(changed, format: .relative(presentation: .named))")
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
            Label {
                Text(isOverdue ? "Change overdue" : "Change due \(dueText(due, now: now))")
            } icon: {
                Image(systemName: isOverdue ? "exclamationmark.triangle.fill" : "calendar")
            }
            .font(.subheadline.weight(isOverdue ? .semibold : .regular))
            .foregroundStyle(isOverdue ? Theme.vermilion : Theme.soft)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Logs a new site change")
    }

    private func dueText(_ due: Date, now: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(due) {
            return "today at \(due.formatted(date: .omitted, time: .shortened))"
        }
        if calendar.isDateInTomorrow(due) {
            return "tomorrow"
        }
        return due.formatted(.dateTime.weekday(.wide))
    }
}
