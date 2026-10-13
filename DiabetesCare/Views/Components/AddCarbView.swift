//
//  AddCarbView.swift
//  DiabetesCare
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
    @State private var showFoodSearch = false
    /// Foods picked from the lookup, shown as a list under the button.
    @State private var picks: [FoodPick] = []
    @State private var photo: Data?

    private var grams: Double? {
        parseNumber(gramsText).flatMap { EntryLimits.carbGrams.contains($0) ? $0 : nil }
    }

    var body: some View {
        EntryForm(
            title: "Add Carbs",
            canSave: grams != nil,
            hasChanges: !gramsText.isEmpty || !foodItems.isEmpty || !notes.isEmpty || photo != nil,
            onSave: save
        ) {
            Section {
                Button("Look Up Carbs", systemImage: "magnifyingglass") { showFoodSearch = true }
                    .accessibilityIdentifier("lookUpCarbs")
                ForEach(Array(picks.enumerated()), id: \.offset) { _, pick in
                    LabeledContent(pick.name, value: "\(Int(pick.carbs)) g")
                        .font(.subheadline)
                }
            } footer: {
                if !picks.isEmpty {
                    Text("Added to the carbs below. You can still change the total.")
                }
            }
            .listRowBackground(Theme.card)
            KitchenScaleSection(gramsText: $gramsText, mealType: $mealType, foodItems: $foodItems)
            CarbFields(gramsText: $gramsText, mealType: $mealType, foodItems: $foodItems, timestamp: $timestamp, notes: $notes, focus: $gramsFocused)
            SitePhotoSection(photo: $photo, subject: String(localized: "Meal photo"), identifier: "mealPhoto")
        }
        .defaultFocus($gramsFocused, true)
        .onAppear { gramsFocused = true }
        .sheet(isPresented: $showFoodSearch) {
            FoodSearchView(onAdd: add)
        }
    }

    /// Adds a looked-up food: its carbs to the total and its name to the list.
    private func add(_ pick: FoodPick) {
        picks.append(pick)
        let total = (parseNumber(gramsText) ?? 0) + pick.carbs
        gramsText = editableNumber(min(total, EntryLimits.carbGrams.upperBound))
        foodItems = foodItems.isEmpty ? pick.name : foodItems + ", " + pick.name
    }

    private func save() -> Bool {
        guard let grams else { return false }
        viewModel.addCarbEntry(
            grams: grams,
            mealType: mealType.rawValue,
            foodItems: foodItems.isEmpty ? nil : foodItems,
            notes: notes.isEmpty ? nil : notes,
            timestamp: timestamp,
            photo: photo
        )
        return true
    }
}

#Preview {
    AddCarbView()
        .environment(LogViewModel(context: PersistenceController.preview.container.viewContext))
}
