//
//  EditActivityView.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI
import CoreData

struct EditActivityView: View {
    let entry: ActivityEntry
    let operation: DraftOperation<NSManagedObject>

    @State private var activityType = ""
    @State private var durationText = ""
    @State private var intensity = ""
    @State private var caloriesText = ""
    @State private var timestamp = Date()
    @State private var notes = ""
    @State private var original: [AnyHashable] = []
    @FocusState private var durationFocused: Bool

    private var current: [AnyHashable] { [activityType, durationText, intensity, caloriesText, timestamp, notes] }

    private var duration: Int16? {
        parseNumber(durationText)
            .flatMap { EntryLimits.activityMinutes.contains($0) ? Int16($0.rounded()) : nil }
    }

    private var calories: Double? {
        guard !caloriesText.isEmpty else { return 0 }
        return parseNumber(caloriesText).flatMap { EntryLimits.calories.contains($0) ? $0 : nil }
    }

    var body: some View {
        EntryForm(
            title: "Edit Activity",
            canSave: duration != nil && calories != nil,
            hasChanges: !original.isEmpty && current != original,
            onSave: save,
            onCancel: operation.cancel
        ) {
            ActivityFields(
                activityType: $activityType,
                durationText: $durationText,
                intensity: $intensity,
                caloriesText: $caloriesText,
                timestamp: $timestamp,
                notes: $notes,
                focus: $durationFocused
            )
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard original.isEmpty else { return }
        activityType = entry.type ?? "Other"
        durationText = "\(entry.duration)"
        intensity = entry.intensity ?? "Moderate"
        caloriesText = entry.caloriesBurned > 0 ? editableNumber(entry.caloriesBurned) : ""
        timestamp = entry.timestamp ?? Date()
        notes = entry.notes ?? ""
        original = current
    }

    private func save() -> Bool {
        guard let duration, let calories else { return false }
        entry.type = activityType
        entry.duration = duration
        entry.intensity = intensity
        entry.caloriesBurned = calories
        entry.timestamp = timestamp
        entry.notes = notes.isEmpty ? nil : notes
        return operation.save()
    }
}
