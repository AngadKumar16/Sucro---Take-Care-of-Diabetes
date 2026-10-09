//
//  AddInsulinView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct AddInsulinView: View {
    @Environment(LogViewModel.self) private var viewModel
    @Environment(SettingsStore.self) private var settings

    @State private var unitsText = ""
    @State private var type: InsulinType = .bolus
    @State private var deliveryMethod: DeliveryMethod = .pen
    @State private var timestamp = Date()
    @State private var notes = ""
    @FocusState private var unitsFocused: Bool

    private var units: Double? {
        parseNumber(unitsText).flatMap { EntryLimits.insulinUnits.contains($0) ? $0 : nil }
    }

    var body: some View {
        EntryForm(
            title: "Add Insulin",
            canSave: units != nil,
            hasChanges: !unitsText.isEmpty || !notes.isEmpty,
            onSave: save
        ) {
            if deliveryMethod == .pen {
                Section {
                    InsulinPen(units: parseNumber(unitsText) ?? 0)
                        .padding(.vertical, 4)
                        .animation(.snappy, value: unitsText)
                }
                .listRowBackground(Theme.card)
            }
            InsulinFields(unitsText: $unitsText, type: $type, deliveryMethod: $deliveryMethod, timestamp: $timestamp, notes: $notes, focus: $unitsFocused)
        }
        .defaultFocus($unitsFocused, true)
        .onAppear {
            deliveryMethod = settings.lastDeliveryMethod
            unitsFocused = true
        }
    }

    private func save() -> Bool {
        guard let units else { return false }
        settings.lastDeliveryMethod = deliveryMethod
        viewModel.addInsulinEntry(
            units: units,
            type: type.rawValue,
            deliveryMethod: deliveryMethod.rawValue,
            notes: notes.isEmpty ? nil : notes,
            timestamp: timestamp
        )
        return true
    }
}

#Preview {
    AddInsulinView()
        .environment(LogViewModel(context: PersistenceController.preview.container.viewContext))
        .environment(SettingsStore())
}
