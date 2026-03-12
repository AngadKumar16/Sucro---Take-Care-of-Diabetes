//
//  AddGlucoseView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct AddGlucoseView: View {
    @EnvironmentObject var viewModel: LogViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var glucoseValue: String = ""
    @State private var selectedUnit: String = "mg/dL"
    @State private var selectedContext: String = "Fasting"
    @State private var notes: String = ""
    
    private let contexts = ["Fasting", "Before Meal", "After Meal", "Bedtime", "Exercise", "Other"]
    private let units = ["mg/dL", "mmol/L"]
    
    var body: some View {
        NavigationView {
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
                        .pickerStyle(SegmentedPickerStyle())
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
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
        .environmentObject(LogViewModel(context: PersistenceController.preview.container.viewContext))
}
