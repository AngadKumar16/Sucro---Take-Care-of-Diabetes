//
//  AddActivityView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct AddActivityView: View {
    @Environment(LogViewModel.self) private var viewModel

    @State private var activityType = "Walking"
    @State private var durationText = ""
    @State private var intensity = "Moderate"
    @State private var caloriesText = ""
    @State private var timestamp = Date()
    @State private var notes = ""
    @FocusState private var durationFocused: Bool

    private var duration: Int16? {
        parseNumber(durationText)
            .flatMap { EntryLimits.activityMinutes.contains($0) ? Int16($0.rounded()) : nil }
    }

    /// Empty calories are fine; a typo isn't.
    private var calories: Double? {
        guard !caloriesText.isEmpty else { return 0 }
        return parseNumber(caloriesText).flatMap { EntryLimits.calories.contains($0) ? $0 : nil }
    }

    var body: some View {
        EntryForm(
            title: "Add Activity",
            canSave: duration != nil && calories != nil,
            hasChanges: !durationText.isEmpty || !caloriesText.isEmpty || !notes.isEmpty,
            onSave: save
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
        .defaultFocus($durationFocused, true)
        .onAppear { durationFocused = true }
    }

    private func save() -> Bool {
        guard let duration, let calories else { return false }
        viewModel.addActivityEntry(
            type: activityType,
            duration: duration,
            intensity: intensity,
            caloriesBurned: calories,
            notes: notes.isEmpty ? nil : notes,
            timestamp: timestamp
        )
        return true
    }
}

#Preview {
    AddActivityView()
        .environment(LogViewModel(context: PersistenceController.preview.container.viewContext))
}
