//
//  AddCarbView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct AddCarbView: View {
    @Environment(LogViewModel.self) private var viewModel

    @State private var gramsText = ""
    @State private var mealType = MealType.likely(at: .now)
    @State private var foodItems = ""
    @State private var timestamp = Date()
    @State private var notes = ""
    @FocusState private var gramsFocused: Bool

    private var grams: Double? {
        parseNumber(gramsText).flatMap { EntryLimits.carbGrams.contains($0) ? $0 : nil }
    }

    var body: some View {
        EntryForm(
            title: "Add Carbs",
            canSave: grams != nil,
            hasChanges: !gramsText.isEmpty || !foodItems.isEmpty || !notes.isEmpty,
            onSave: save
        ) {
            CarbFields(gramsText: $gramsText, mealType: $mealType, foodItems: $foodItems, timestamp: $timestamp, notes: $notes, focus: $gramsFocused)
        }
        .defaultFocus($gramsFocused, true)
        .onAppear { gramsFocused = true }
    }

    private func save() -> Bool {
        guard let grams else { return false }
        viewModel.addCarbEntry(
            grams: grams,
            mealType: mealType.rawValue,
            foodItems: foodItems.isEmpty ? nil : foodItems,
            notes: notes.isEmpty ? nil : notes,
            timestamp: timestamp
        )
        return true
    }
}

#Preview {
    AddCarbView()
        .environment(LogViewModel(context: PersistenceController.preview.container.viewContext))
}
