//
//  RecentTimelineCardsView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI

struct RecentTimelineCardsView: View {
    let events: [TimelineEvent]
    let onShowAll: () -> Void
    let onEventTap: (TimelineEvent) -> Void
    let onEventEdit: (TimelineEvent) -> Void
    let onEventDelete: (TimelineEvent) -> Void
    let onAddNote: (TimelineEvent) -> Void

    @State private var pendingDelete: TimelineEvent?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeader("Logged in View") {
                Button("See All", action: onShowAll)
                    .font(.subheadline)
            }

            if events.isEmpty {
                Text("Nothing logged in this stretch.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .card()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(events.prefix(8).enumerated()), id: \.element.id) { index, event in
                        if index > 0 {
                            Divider().padding(.leading, 60)
                        }
                        TimelineCard(event: event) { onEventTap(event) }
                            .contextMenu {
                                Button("Add Note", systemImage: "note.text.badge.plus") { onAddNote(event) }
                                Button("Edit", systemImage: "pencil") { onEventEdit(event) }
                                Divider()
                                Button("Delete", systemImage: "trash", role: .destructive) { pendingDelete = event }
                            }
                            .accessibilityAction(named: "Add Note") { onAddNote(event) }
                            .accessibilityAction(named: "Edit") { onEventEdit(event) }
                            .accessibilityAction(named: "Delete") { pendingDelete = event }
                    }
                }
                .instrumentPanel(padding: 0)
            }
        }
        .confirmationDialog(
            "Delete \(pendingDelete?.title ?? "Entry")?",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { event in
            Button("Delete", role: .destructive) { onEventDelete(event) }
        } message: { _ in
            Text("This can't be undone.")
        }
    }
}

struct TimelineCard: View {
    @Environment(SettingsStore.self) private var settings
    let event: TimelineEvent
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: event.icon)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.green)
                    .frame(width: 36, height: 36)
                    .background(Theme.card)
                    .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: 1.5))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    HStack(spacing: 4) {
                        if let subtitle = event.subtitle {
                            Text(subtitle)
                        }
                        Text("·")
                            .accessibilityHidden(true)
                        Text(event.timestamp, format: .relative(presentation: .named, unitsStyle: .abbreviated))
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }

                Spacer(minLength: 8)

                if let glucose = event.glucoseValue {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(settings.glucoseValueString(glucose))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(settings.zone(for: glucose).color)
                        Text(settings.glucoseUnit)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Glucose \(settings.formattedGlucose(glucose))")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Shows details")
    }
}

#Preview {
    RecentTimelineCardsView(
        events: [
            TimelineEvent(type: .meal, timestamp: Date().addingTimeInterval(-1800), glucoseValue: 145, title: "Lunch", subtitle: "45g carbs"),
            TimelineEvent(type: .bolus, timestamp: Date().addingTimeInterval(-2100), glucoseValue: 150, title: "Bolus", subtitle: "5 units"),
            TimelineEvent(type: .activity, timestamp: Date().addingTimeInterval(-3600), glucoseValue: 110, title: "Walk", subtitle: "30 min"),
            TimelineEvent(type: .siteChange, timestamp: Date().addingTimeInterval(-7200), glucoseValue: 95, title: "Site Change", subtitle: "Abdomen Left")
        ],
        onShowAll: {},
        onEventTap: { _ in },
        onEventEdit: { _ in },
        onEventDelete: { _ in },
        onAddNote: { _ in }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
    .environment(SettingsStore())
}
