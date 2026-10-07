//
//  InsulinSettingsSection.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// Settings card for the insulin action time used by the IOB estimate.
struct InsulinSettingsSection: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insulin")
                .font(.headline)

            Stepper(value: Bindable(settings).insulinActionHours, in: SettingsStore.insulinActionBounds, step: 0.5) {
                LabeledContent("Insulin Action Time") {
                    Text("\(settings.insulinActionHours, format: .number) hr")
                }
                .font(.subheadline)
            }
            .padding(.vertical, 8)
            .accessibilityIdentifier("insulinActionTime")

            Text("How long your rapid-acting insulin keeps working. Used only for the insulin on board estimate on Home. Ask your care team if you're not sure.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6), in: .rect(cornerRadius: 12))
    }
}
