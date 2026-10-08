//
//  EditCarbView.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI
import CoreData

struct EditCarbView: View {
    let entry: CarbEntry
    let operation: DraftOperation<NSManagedObject>

    @State private var gramsText = ""
    @State private var mealType: MealType = .other
    @State private var foodItems = ""
    @State private var timestamp = Date()
    @State private var notes = ""
    @State private var original: [AnyHashable] = []
    @FocusState private var gramsFocused: Bool

    private var current: [AnyHashable] { [gramsText, mealType, foodItems, timestamp, notes] }

    private var grams: Double? {
        parseNumber(gramsText).flatMap { EntryLimits.carbGrams.contains($0) ? $0 : nil }
    }

    var body: some View {
        EntryForm(
            title: "Edit Carbs",
            canSave: grams != nil,
            hasChanges: !original.isEmpty && current != original,
            onSave: save,
            onCancel: operation.cancel
        ) {
            CarbFields(gramsText: $gramsText, mealType: $mealType, foodItems: $foodItems, timestamp: $timestamp, notes: $notes, focus: $gramsFocused)
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard original.isEmpty else { return }
        gramsText = editableNumber(entry.grams)
        mealType = MealType(stored: entry.mealType) ?? .other
        foodItems = entry.foodItems ?? ""
        timestamp = entry.timestamp ?? Date()
        notes = entry.notes ?? ""
        original = current
    }

    private func save() -> Bool {
        guard let grams else { return false }
        entry.grams = grams
        entry.mealType = mealType.rawValue
        entry.foodItems = foodItems.isEmpty ? nil : foodItems
        entry.timestamp = timestamp
        entry.notes = notes.isEmpty ? nil : notes
        return operation.save()
    }
}
