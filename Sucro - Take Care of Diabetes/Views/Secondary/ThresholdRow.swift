//
//  ThresholdRow.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// A glucose threshold shown in the user's unit and adjusted in 5 mg/dL
/// steps. Bounds keep the four thresholds in order.
struct ThresholdRow: View {
    @Environment(SettingsStore.self) private var settings
    let title: String
    @Binding var value: Double
    let bounds: ClosedRange<Double>

    var body: some View {
        Stepper(value: $value, in: bounds, step: SettingsStore.thresholdStep) {
            LabeledContent(title) {
                Text(settings.formattedGlucose(value))
                    .monospacedDigit()
            }
            .font(.subheadline)
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("threshold.\(title)")
    }
}
