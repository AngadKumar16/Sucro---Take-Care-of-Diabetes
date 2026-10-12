//
//  InsulinSettingsSection.swift
//  DiabetesCare
//

import SwiftUI

/// Settings section for the insulin action time used by the IOB estimate.
struct InsulinSettingsSection: View {
    @Environment(SettingsStore.self) private var settings
    /// A kid's insulin settings need a grown-up.
    var locked = false
    var onUnlock: () -> Void = {}

    var body: some View {
        Section {
            Stepper(value: Bindable(settings).insulinActionHours, in: SettingsStore.insulinActionBounds, step: 0.5) {
                LabeledContent("Insulin Action Time") {
                    Text("\(settings.insulinActionHours, format: .number) hr")
                        .monospacedDigit()
                }
            }
            .accessibilityIdentifier("insulinActionTime")
            .disabled(locked)
            if locked {
                Button("Unlock to Change", systemImage: "lock.fill", action: onUnlock)
            }
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
