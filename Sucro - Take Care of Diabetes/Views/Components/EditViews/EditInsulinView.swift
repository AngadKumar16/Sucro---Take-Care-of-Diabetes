//
//  EditInsulinView.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI
import CoreData

struct EditInsulinView: View {
    let entry: InsulinEntry
    let operation: DraftOperation<NSManagedObject>

    @State private var unitsText = ""
    @State private var type: InsulinType = .bolus
    @State private var deliveryMethod: DeliveryMethod = .pen
    @State private var timestamp = Date()
    @State private var notes = ""
    @State private var original: [AnyHashable] = []
    @FocusState private var unitsFocused: Bool

    private var current: [AnyHashable] { [unitsText, type, deliveryMethod, timestamp, notes] }

    private var units: Double? {
        parseNumber(unitsText).flatMap { EntryLimits.insulinUnits.contains($0) ? $0 : nil }
    }

    var body: some View {
        EntryForm(
            title: "Edit Insulin",
            canSave: units != nil,
            hasChanges: !original.isEmpty && current != original,
            onSave: save,
            onCancel: operation.cancel
        ) {
            InsulinFields(unitsText: $unitsText, type: $type, deliveryMethod: $deliveryMethod, timestamp: $timestamp, notes: $notes, focus: $unitsFocused)
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard original.isEmpty else { return }
        unitsText = editableNumber(entry.units)
        type = InsulinType(stored: entry.type) ?? .other
        deliveryMethod = DeliveryMethod(stored: entry.deliveryMethod) ?? .pen
        timestamp = entry.timestamp ?? Date()
        notes = entry.notes ?? ""
        original = current
    }

    private func save() -> Bool {
        guard let units else { return false }
        entry.units = units
        entry.type = type.rawValue
        entry.deliveryMethod = deliveryMethod.rawValue
        entry.timestamp = timestamp
        entry.notes = notes.isEmpty ? nil : notes
        return operation.save()
    }
}
