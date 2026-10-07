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
    @Environment(\.dismiss) var dismiss

    @State private var glucoseValue: String = ""
    @State private var selectedUnit: String = "mg/dL"
    @State private var selectedContext: String = "Fasting"
    @State private var notes: String = ""
    
    private let contexts = ["Fasting", "Before Meal", "After Meal", "Bedtime", "Exercise", "Other"]
    private let units = ["mg/dL", "mmol/L"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Glucose Reading")) {
                    HStack {
                        TextField("Enter value", text: $glucoseValue)
                            .keyboardType(.decimalPad)
                        
                        Picker("Unit", selection: $selectedUnit) {
                            ForEach(units, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }
                    
                    Picker("Context", selection: $selectedContext) {
                        ForEach(contexts, id: \.self) { context in
                            Text(context).tag(context)
                        }
                    }
                }
                
                Section(header: Text("Notes (Optional)")) {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Glucose")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { selectedUnit = settings.glucoseUnit }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveGlucoseReading()
                    }
                    .disabled(glucoseValue.isEmpty || Double(glucoseValue) == nil)
                }
            }
        }
    }
    
    private func saveGlucoseReading() {
        guard let value = Double(glucoseValue) else { return }
        
        var convertedValue = value
        if selectedUnit == "mmol/L" {
            convertedValue = value * 18.018 // Convert to mg/dL
        }
        
        viewModel.addGlucoseReading(
            value: convertedValue,
            unit: "mg/dL",
            context: selectedContext,
            notes: notes.isEmpty ? nil : notes
        )
        
        dismiss()
    }
}

#Preview {
    AddGlucoseView()
        .environment(LogViewModel(context: PersistenceController.preview.container.viewContext))
        .environment(SettingsStore())
}
