//
//  InsulinSettingsSection.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// Settings section for the insulin action time used by the IOB estimate.
struct InsulinSettingsSection: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        Section {
            Stepper(value: Bindable(settings).insulinActionHours, in: SettingsStore.insulinActionBounds, step: 0.5) {
                LabeledContent("Insulin Action Time") {
                    Text("\(settings.insulinActionHours, format: .number) hr")
                        .monospacedDigit()
                }
            }
            .accessibilityIdentifier("insulinActionTime")
        } header: {
            Text("Insulin")
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text("How long your rapid-acting insulin keeps working. Used only for the insulin on board estimate on Today. Ask your care team if you're not sure.")
                GlossaryLink(termID: "insulin-action-time", title: "About insulin action time")
            }
        }
        .listRowBackground(Theme.card)
    }
}
