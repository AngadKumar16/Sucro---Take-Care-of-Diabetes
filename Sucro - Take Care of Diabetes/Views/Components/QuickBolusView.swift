//
//  QuickBolusView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import SwiftUI
import CoreData

struct QuickBolusView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(HomeViewModel.self) private var viewModel
    
    @State private var units: Double = 0.0
    @State private var selectedPreset: BolusPreset?
    @State private var notes: String = ""
    @State private var confirmLargeDose = false

    /// Doses above this ask for confirmation before they're logged, to catch
    /// a slip of the slider or stepper.
    private let largeDoseUnits = 10.0
    
    let presets = [
        BolusPreset(name: "Small", units: 2.0),
        BolusPreset(name: "Medium", units: 4.0),
        BolusPreset(name: "Large", units: 6.0),
        BolusPreset(name: "Correction", units: 3.0)
    ]
    
    var body: some View {
        NavigationStack {
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
                        Text(units.formatted(.number.precision(.fractionLength(1))))
                            .font(.title2)
                            .bold()
                    }
                    
                    Slider(value: $units, in: 0...20, step: 0.5)
                    
                    Stepper("Adjust: \(units.formatted(.number.precision(.fractionLength(1)))) units", value: $units, in: 0...30, step: 0.5)
                }
                
                Section("Notes (Optional)") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }
                
                Section {
                    Button("Log Bolus") {
                        if units > largeDoseUnits {
                            confirmLargeDose = true
                        } else {
                            logBolus()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .padding()
                    .background(units > 0 ? Color.blue : Color.gray)
                    .clipShape(.rect(cornerRadius: 8))
                    .disabled(units <= 0)
                } footer: {
                    Text("This records a dose you've taken or are taking. It doesn't control your pump.")
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
            .alert("Log \(units, format: .number) units?", isPresented: $confirmLargeDose) {
                Button("Log Dose") { logBolus() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("That's more than \(Int(largeDoseUnits)) units. Make sure the amount is right.")
            }
        }
    }

    private func logBolus() {
        // Create insulin entry
        let timestamp = Date()
        let entry = InsulinEntry(context: viewModel.viewContext)
        entry.id = UUID()
        entry.units = units
        entry.type = InsulinType.bolus.rawValue
        entry.deliveryMethod = "Quick Bolus"
        entry.timestamp = timestamp
        entry.notes = notes.isEmpty ? nil : notes

        viewModel.save()
        HealthKitManager.shared.saveInsulinDose(units, type: InsulinType.bolus.rawValue, timestamp: timestamp)
        viewModel.fetchLatestData() // Refresh IOB, totals and reminders
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
                Text("\(preset.units.formatted(.number.precision(.fractionLength(1)))) U")
                    .font(.title3)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
            .foregroundStyle(isSelected ? .blue : .primary)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            }
            .clipShape(.rect(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuickBolusView()
        .environment(HomeViewModel(context: PersistenceController.preview.container.viewContext))
}
