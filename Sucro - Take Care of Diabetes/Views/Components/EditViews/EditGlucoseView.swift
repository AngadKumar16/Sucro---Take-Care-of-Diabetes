//
//  EditGlucoseView.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI
import CoreData

struct EditGlucoseView: View {
    @Environment(SettingsStore.self) private var settings
    let entry: GlucoseReading
    let operation: DraftOperation<NSManagedObject>

    @State private var valueText = ""
    @State private var context: GlucoseContext = .other
    @State private var timestamp = Date()
    @State private var notes = ""
    @State private var original: [AnyHashable] = []
    @FocusState private var valueFocused: Bool

    private var current: [AnyHashable] { [valueText, context, timestamp, notes] }

    var body: some View {
        EntryForm(
            title: "Edit Glucose",
            canSave: parsedGlucose(valueText, settings: settings) != nil,
            hasChanges: !original.isEmpty && current != original,
            onSave: save,
            onCancel: operation.cancel
        ) {
            GlucoseFields(valueText: $valueText, context: $context, timestamp: $timestamp, notes: $notes, focus: $valueFocused)
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard original.isEmpty else { return }
        valueText = settings.glucoseValueString(entry.value)
        context = GlucoseContext(stored: entry.context) ?? .other
        timestamp = entry.timestamp ?? Date()
        notes = entry.notes ?? ""
        original = current
    }

    private func save() -> Bool {
        guard let mgdl = parsedGlucose(valueText, settings: settings) else { return false }
        // Leave the stored value alone unless the number shown was changed,
        // so a mmol/L round trip doesn't nudge it.
        if valueText != settings.glucoseValueString(entry.value) {
            entry.value = mgdl
        }
        entry.context = context.rawValue
        entry.timestamp = timestamp
        entry.notes = notes.isEmpty ? nil : notes
        return operation.save()
    }
}
