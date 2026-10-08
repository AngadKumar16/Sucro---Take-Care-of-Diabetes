//
//  SiteSnapshotView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

/// The current infusion site: where it is, how old it is and when it's
/// due. Tapping it logs a new site change.
struct SiteSnapshotView: View {
    let lastSiteChange: SiteChange?
    let onChangeSite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeader("Infusion Site")

            Button(action: onChangeSite) {
                Group {
                    if let siteChange = lastSiteChange, let changed = siteChange.timestamp {
                        TimelineView(.periodic(from: .now, by: 60)) { context in
                            currentSite(siteChange, changed: changed, now: context.date)
                        }
                    } else {
                        emptyState
                    }
                }
                .card()
                .contentShape(.rect(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }

    private func currentSite(_ siteChange: SiteChange, changed: Date, now: Date) -> some View {
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

    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "bandage")
                .font(.title3)
                .foregroundStyle(.purple)
                .frame(width: 44, height: 44)
                .background(Color.purple.opacity(0.15), in: .circle)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("No Site Logged")
                    .font(.headline)
                Text("Log your next site change to get a reminder when it's due.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Logs a site change")
    }

    /// "today at 3:00 PM", "tomorrow", or a weekday for later dates.
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

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let siteChange = SiteChange(context: context)
    siteChange.location = "Abdomen Left"
    siteChange.timestamp = Date().addingTimeInterval(-86400)
    return VStack(spacing: 20) {
        SiteSnapshotView(lastSiteChange: siteChange, onChangeSite: {})
        SiteSnapshotView(lastSiteChange: nil, onChangeSite: {})
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
