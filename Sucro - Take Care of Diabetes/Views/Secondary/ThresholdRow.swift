//
//  ThresholdRow.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// A stepper for one glucose threshold, shown in the user's unit.
struct ThresholdRow: View {
    @Environment(SettingsStore.self) private var settings
    let title: String
    let color: Color
    @Binding var value: Double
    let bounds: ClosedRange<Double>

    var body: some View {
        Stepper(value: $value, in: bounds, step: SettingsStore.thresholdStep) {
            LabeledContent {
                Text(settings.formattedGlucose(value))
                    .monospacedDigit()
            } label: {
                HStack(spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)
                        .accessibilityHidden(true)
                    Text(title)
                }
            }
        }
        .accessibilityIdentifier("threshold.\(title)")
    }
}
