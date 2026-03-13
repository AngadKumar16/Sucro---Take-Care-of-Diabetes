//
//  EditCarbView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import SwiftUI

struct EditCarbView: View {
    @ObservedObject var entry: CarbEntry
    
    // Explicit custom bindings
    private var foodItemsBinding: Binding<String> {
        Binding(
            get: { entry.foodItems ?? "" },
            set: { entry.foodItems = $0.isEmpty ? nil : $0 }
        )
    }
    
    private var mealTypeBinding: Binding<String> {
        Binding(
            get: { entry.mealType ?? "snack" },
            set: { entry.mealType = $0 }
        )
    }
    
    private var timestampBinding: Binding<Date> {
        Binding(
            get: { entry.timestamp ?? Date() },
            set: { entry.timestamp = $0 }
        )
    }
    
    private var notesBinding: Binding<String> {
        Binding(
            get: { entry.notes ?? "" },
            set: { entry.notes = $0.isEmpty ? nil : $0 }
        )
    }
    
    var body: some View {
        Form {
            Section("Meal Details") {
                TextField("Food Items", text: foodItemsBinding)
                
                Picker("Meal Type", selection: mealTypeBinding) {
                    Text("Breakfast").tag("breakfast")
                    Text("Lunch").tag("lunch")
                    Text("Dinner").tag("dinner")
                    Text("Snack").tag("snack")
                }
                
                HStack {
                    Text("Carbs (g)")
                    Spacer()
                    TextField("Grams", value: $entry.grams, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                DatePicker("Time", selection: timestampBinding)
            }
            
            Section("Notes") {
                TextEditor(text: notesBinding)
                    .frame(height: 100)
            }
        }
    }
}
