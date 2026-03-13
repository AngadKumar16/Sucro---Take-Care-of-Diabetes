//
//  QuickBolusView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import SwiftUI
import CoreData  // ADD THIS

struct QuickBolusView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: HomeViewModel
    
    @State private var units: Double = 0.0
    @State private var selectedPreset: BolusPreset?
    @State private var notes: String = ""
    
    let presets = [
        BolusPreset(name: "Small", units: 2.0),
        BolusPreset(name: "Medium", units: 4.0),
        BolusPreset(name: "Large", units: 6.0),
        BolusPreset(name: "Correction", units: 3.0)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Quick Presets") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(presets) { preset in
                            PresetButton(
                                preset: preset,
                                isSelected: selectedPreset?.id == preset.id,
                                onTap: {
                                    selectedPreset = preset
                                    units = preset.units
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Custom Amount") {
                    HStack {
                        Text("Units")
                        Spacer()
                        Text(String(format: "%.1f", units))
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Slider(value: $units, in: 0...20, step: 0.5)
                    
                    Stepper("Adjust: \(String(format: "%.1f", units)) units", value: $units, in: 0...30, step: 0.5)
                }
                
                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
                
                Section {
                    Button("Deliver Bolus") {
                        deliverBolus()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(units > 0 ? Color.blue : Color.gray)
                    .cornerRadius(8)
                    .disabled(units <= 0)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Quick Bolus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func deliverBolus() {
        // Create insulin entry
        let entry = InsulinEntry(context: viewModel.viewContext)
        entry.id = UUID()
        entry.units = units
        entry.type = InsulinType.bolus.rawValue
        entry.deliveryMethod = "Quick Bolus"
        entry.timestamp = Date()
        entry.notes = notes.isEmpty ? nil : notes
        
        viewModel.save()
        viewModel.fetchLatestData() // Refresh IOB and totals
        
        // Send notification for high bolus
        if units > 10 {
            NotificationService.shared.scheduleCriticalGlucoseAlert(value: 0, isLow: false) // Just a notification
        }
        
        dismiss()
    }
}

struct PresetButton: View {
    let preset: BolusPreset
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(preset.name)
                    .font(.headline)
                Text(String(format: "%.1f U", preset.units))
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
            .foregroundColor(isSelected ? .blue : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    QuickBolusView()
        .environmentObject(HomeViewModel(context: PersistenceController.preview.container.viewContext))
}
