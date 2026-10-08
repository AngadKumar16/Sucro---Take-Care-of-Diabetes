//
//  EventDetailView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import SwiftUI

struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsStore.self) private var settings
    let event: TimelineEvent
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onAddNote: () -> Void

    @State private var showingDeleteConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: event.icon)
                            .font(.title2.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(event.color.gradient, in: .circle)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(.title3.bold())
                            if let subtitle = event.subtitle {
                                Text(subtitle)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)

                    LabeledContent("Time", value: event.timestamp.formatted(date: .abbreviated, time: .shortened))
                    if let glucose = event.glucoseValue {
                        LabeledContent("Glucose at the Time") {
                            Text(settings.formattedGlucose(glucose))
                                .foregroundStyle(settings.zone(for: glucose).color)
                        }
                    }
                }

                Section("Notes") {
                    if let notes = event.notes, !notes.isEmpty {
                        Text(notes)
                            .textSelection(.enabled)
                    }
                    Button("Add Note", systemImage: "note.text.badge.plus", action: onAddNote)
                }

                Section {
                    Button("Edit", systemImage: "pencil", action: onEdit)
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        showingDeleteConfirm = true
                    }
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Delete \(event.title)?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text("This can't be undone.")
            }
        }
    }
}

#Preview {
    EventDetailView(
        event: TimelineEvent(
            type: .meal,
            timestamp: Date(),
            glucoseValue: 120,
            title: "Lunch",
            subtitle: "45g carbs",
            notes: "Pasta at the office"
        ),
        onEdit: {},
        onDelete: {},
        onAddNote: {}
    )
    .environment(SettingsStore())
}
