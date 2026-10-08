//
//  AddGlucoseView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct AddGlucoseView: View {
    @Environment(LogViewModel.self) private var viewModel
    @Environment(SettingsStore.self) private var settings

    @State private var valueText = ""
    @State private var context = GlucoseContext.likely(at: .now)
    @State private var timestamp = Date()
    @State private var notes = ""
    @FocusState private var valueFocused: Bool

    var body: some View {
        EntryForm(
            title: "Add Glucose",
            canSave: parsedGlucose(valueText, settings: settings) != nil,
            hasChanges: !valueText.isEmpty || !notes.isEmpty,
            onSave: save
        ) {
            GlucoseFields(valueText: $valueText, context: $context, timestamp: $timestamp, notes: $notes, focus: $valueFocused)
        }
        .defaultFocus($valueFocused, true)
        .onAppear { valueFocused = true }
    }

    private func save() -> Bool {
        guard let mgdl = parsedGlucose(valueText, settings: settings) else { return false }
        viewModel.addGlucoseReading(
            value: mgdl,
            unit: "mg/dL",
            context: context.rawValue,
            notes: notes.isEmpty ? nil : notes,
            timestamp: timestamp
        )
        return true
    }
}

#Preview {
    AddGlucoseView()
        .environment(LogViewModel(context: PersistenceController.preview.container.viewContext))
        .environment(SettingsStore())
}
