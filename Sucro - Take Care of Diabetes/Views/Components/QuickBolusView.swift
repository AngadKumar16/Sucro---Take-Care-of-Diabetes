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
    @State private var units: Double = 0
    @State private var notes = ""
    @State private var confirmLargeDose = false
    @State private var confirmDiscard = false

    /// Doses above this ask for confirmation before they're logged, to catch
    /// a slip of the stepper or a preset.
    private let largeDoseUnits = 10.0
    private let maxUnits = 30.0

    let presets = [
        BolusPreset(name: "Small", units: 2.0),
        BolusPreset(name: "Medium", units: 4.0),
        BolusPreset(name: "Large", units: 6.0),
        BolusPreset(name: "Correction", units: 3.0)
    ]

    private var hasChanges: Bool { units > 0 || !notes.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    InsulinPen(units: units)
                        .padding(.top, 6)
                        .animation(.snappy, value: units)
                    VStack(spacing: 4) {
                        Text(units, format: .number.precision(.fractionLength(1)))
                            .font(.system(size: 56, weight: .semibold, design: .serif).monospacedDigit())
                            .monospacedDigit()
                            .contentTransition(.numericText(value: units))
                        Text("units")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .accessibilityElement(children: .combine)

                    Stepper("Adjust by 0.5 units", value: $units.animation(.snappy), in: 0...maxUnits, step: 0.5)
                        .accessibilityValue("\(units.formatted(.number.precision(.fractionLength(1)))) units")
                        .accessibilityIdentifier("bolusStepper")
                } footer: {
                    Text("This records a dose you've taken or are taking. It doesn't control your pump.")
                }
                .listRowBackground(Theme.card)

                Section("Presets") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(presets) { preset in
                            PresetButton(preset: preset, isSelected: units == preset.units) {
                                withAnimation(.snappy) { units = preset.units }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                .listRowBackground(Theme.card)

                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(2...6)
                }

                .listRowBackground(Theme.card)
            }
            .instrumentBackground()
            .navigationTitle("Quick Bolus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges { confirmDiscard = true } else { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log Bolus") {
                        if units > largeDoseUnits {
                            confirmLargeDose = true
                        } else {
                            logBolus()
                        }
                    }
                    .disabled(units <= 0)
                }
            }
            .alert("Log \(units, format: .number) units?", isPresented: $confirmLargeDose) {
                Button("Log Dose") { logBolus() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("That's more than \(Int(largeDoseUnits)) units. Make sure the amount is right.")
            }
            .confirmationDialog("Discard this bolus?", isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button("Discard Changes", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            }
        }
        .interactiveDismissDisabled(hasChanges)
    }

    private func logBolus() {
        let timestamp = Date()
        let entry = InsulinEntry(context: viewModel.viewContext)
        entry.id = UUID()
        entry.units = units
        entry.type = InsulinType.bolus.rawValue
        entry.deliveryMethod = SettingsStore.shared.lastDeliveryMethod.rawValue
        entry.timestamp = timestamp
        entry.notes = notes.isEmpty ? nil : notes

        viewModel.save()
        HealthKitManager.shared.saveInsulinDose(units, type: InsulinType.bolus.rawValue, timestamp: timestamp)
        viewModel.fetchLatestData() // Refresh IOB, totals and reminders
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

struct PresetButton: View {
    let preset: BolusPreset
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(preset.name)
                    .font(.subheadline.weight(.semibold))
                Text("\(preset.units.formatted(.number.precision(.fractionLength(1)))) U")
                    .font(Theme.mono(.subheadline))
            }
        }
        .buttonStyle(PrintButtonStyle(kind: isSelected ? .primary : .secondary))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    QuickBolusView()
        .environment(HomeViewModel(context: PersistenceController.preview.container.viewContext))
}
