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

        return HStack(spacing: 12) {
            Image(systemName: "bandage.fill")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.purple.gradient, in: .circle)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.headline)
                Text("Inserted \(changed, format: .relative(presentation: .named))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label {
                    Text(isOverdue ? "Change overdue" : "Change due \(dueText(due, now: now))")
                } icon: {
                    Image(systemName: isOverdue ? "exclamationmark.triangle.fill" : "calendar")
                }
                .font(.subheadline.weight(isOverdue ? .semibold : .regular))
                .foregroundStyle(isOverdue ? .orange : .secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
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
