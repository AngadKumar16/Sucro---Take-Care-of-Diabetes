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
    @Environment(\.dismiss) var dismiss
    
    @State private var insulinUnits: String = ""
    @State private var selectedType: InsulinType = .bolus
    @State private var selectedDeliveryMethod: String = "Pump"
    @State private var notes: String = ""
    
    private let deliveryMethods = ["Pump", "Pen", "Syringe"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Insulin Entry")) {
                    HStack {
                        TextField("Enter units", text: $insulinUnits)
                            .keyboardType(.decimalPad)
                        Text("units")
                            .foregroundStyle(.secondary)
                    }
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(InsulinType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    Picker("Delivery Method", selection: $selectedDeliveryMethod) {
                        ForEach(deliveryMethods, id: \.self) { method in
                            Text(method).tag(method)
                        }
                    }
                }
                
                Section(header: Text("Notes (Optional)")) {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Insulin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveInsulinEntry()
                    }
                    .disabled(insulinUnits.isEmpty || Double(insulinUnits) == nil)
                }
            }
        }
    }
    
    private func saveInsulinEntry() {
        guard let units = Double(insulinUnits) else { return }
        
        viewModel.addInsulinEntry(
            units: units,
            type: selectedType.rawValue,
            deliveryMethod: selectedDeliveryMethod,
            notes: notes.isEmpty ? nil : notes
        )
        
        dismiss()
    }
}

#Preview {
    AddInsulinView()
        .environment(LogViewModel(context: PersistenceController.preview.container.viewContext))
}
