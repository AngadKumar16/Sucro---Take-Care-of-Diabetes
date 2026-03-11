//
//  AddCarbView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI

struct AddCarbView: View {
    @EnvironmentObject var viewModel: LogViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var carbGrams: String = ""
    @State private var selectedMealType: String = "Breakfast"
    @State private var foodItems: String = ""
    @State private var notes: String = ""
    
    private let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack", "Other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Carbohydrate Entry")) {
                    HStack {
                        TextField("Enter grams", text: $carbGrams)
                            .keyboardType(.decimalPad)
                        Text("grams")
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Meal Type", selection: $selectedMealType) {
                        ForEach(mealTypes, id: \.self) { mealType in
                            Text(mealType).tag(mealType)
                        }
                    }
                }
                
                Section(header: Text("Food Items (Optional)")) {
                    TextField("Describe food items...", text: $foodItems, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Notes (Optional)")) {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Carbs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCarbEntry()
                    }
                    .disabled(carbGrams.isEmpty || Double(carbGrams) == nil)
                }
            }
        }
    }
    
    private func saveCarbEntry() {
        guard let grams = Double(carbGrams) else { return }
        
        viewModel.addCarbEntry(
            grams: grams,
            mealType: selectedMealType,
            foodItems: foodItems.isEmpty ? nil : foodItems,
            notes: notes.isEmpty ? nil : notes
        )
        
        dismiss()
    }
}

#Preview {
    AddCarbView()
        .environmentObject(LogViewModel(context: PersistenceController.preview.container.viewContext))
}
