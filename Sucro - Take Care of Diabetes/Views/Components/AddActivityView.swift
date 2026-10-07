//
//  AddActivityView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct AddActivityView: View {
    @Environment(LogViewModel.self) private var viewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedActivityType: String = "Walking"
    @State private var duration: String = ""
    @State private var selectedIntensity: String = "Moderate"
    @State private var caloriesBurned: String = ""
    @State private var notes: String = ""
    
    private let activityTypes = ["Walking", "Running", "Cycling", "Swimming", "Gym", "Yoga", "Other"]
    private let intensities = ["Light", "Moderate", "Vigorous"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Activity Details")) {
                    Picker("Activity Type", selection: $selectedActivityType) {
                        ForEach(activityTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    HStack {
                        TextField("Duration", text: $duration)
                            .keyboardType(.numberPad)
                        Text("minutes")
                            .foregroundStyle(.secondary)
                    }
                    
                    Picker("Intensity", selection: $selectedIntensity) {
                        ForEach(intensities, id: \.self) { intensity in
                            Text(intensity).tag(intensity)
                        }
                    }
                    
                    HStack {
                        TextField("Calories", text: $caloriesBurned)
                            .keyboardType(.decimalPad)
                        Text("kcal")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(header: Text("Notes (Optional)")) {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveActivityEntry()
                    }
                    .disabled(duration.isEmpty || Int16(duration) == nil)
                }
            }
        }
    }
    
    private func saveActivityEntry() {
        guard let durationMinutes = Int16(duration) else { return }
        let calories = Double(caloriesBurned) ?? 0.0
        
        viewModel.addActivityEntry(
            type: selectedActivityType,
            duration: durationMinutes,
            intensity: selectedIntensity,
            caloriesBurned: calories,
            notes: notes.isEmpty ? nil : notes
        )
        
        dismiss()
    }
}

#Preview {
    AddActivityView()
        .environment(LogViewModel(context: PersistenceController.preview.container.viewContext))
}
