//
//  FirstReadingCard.swift
//  Sucro - Take Care of Diabetes
//
//  What Today shows before there are any readings: a meter you set by
//  scrubbing the ruler under it, and a button that logs that number. The
//  full form is one tap away for a time, context or note.
//

import SwiftUI

struct FirstReadingCard: View {
    @Environment(SettingsStore.self) private var settings
    /// Saves a reading in mg/dL, taken now.
    let onLog: (Double) -> Void
    /// Opens the full glucose form.
    let onMoreDetails: () -> Void

    @State private var mgdl: Double = 110
    @State private var logged = 0

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text("What did your meter say?")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("Slide the ruler until it matches.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.soft)
            }
            .multilineTextAlignment(.center)

            GlucoseMeter(
                value: settings.glucoseValueString(mgdl),
                unit: settings.glucoseUnit,
                zone: settings.zone(for: mgdl)
            )
            .animation(.snappy, value: mgdl)

            RulerTape(
                value: $mgdl,
                bounds: GlucoseRangeBar.scale,
                step: 1,
                needle: settings.zone(for: mgdl).color,
                tickWidth: 4
            )
            .padding(.top, 6)
            .accessibilityRepresentation {
                Slider(value: $mgdl, in: GlucoseRangeBar.scale, step: 1) {
                    Text("Glucose")
                }
                .accessibilityValue(settings.formattedGlucose(mgdl))
            }

            VStack(spacing: 10) {
                Button {
                    onLog(mgdl)
                    logged += 1
                } label: {
                    Text("Save \(settings.glucoseValueString(mgdl)) \(settings.glucoseUnit)")
                        .contentTransition(.numericText())
                }
                .buttonStyle(.soft)
                .accessibilityIdentifier("firstReading.log")

                Button("Add a time, note or meal", action: onMoreDetails)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.green)
                    .frame(minHeight: 44)
            }
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .card()
        .sensoryFeedback(.success, trigger: logged)
    }
}

#Preview {
    FirstReadingCard(onLog: { _ in }, onMoreDetails: {})
        .padding()
        .instrumentBackground()
        .environment(SettingsStore())
}
