//
//  UnitsGuideView.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// Explains mg/dL and mmol/L with a live converter and landmark values.
struct UnitsGuideView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var mgdl: Double = 120

    private static let factor = 18.0182
    private let landmarks: [(mgdl: Double, label: String)] = [
        (54, "Level 2 low"),
        (70, "Common low line"),
        (130, "Before-meal goal top"),
        (180, "Common high line"),
        (250, "Common urgent high")
    ]

    var body: some View {
        let zone = settings.zone(for: mgdl)

        GuidePage(guide: .units) {
            GuideSection(title: "Try It") {
                VStack(spacing: 16) {
                    HStack(alignment: .firstTextBaseline) {
                        reading(mgdl.formatted(.number.precision(.fractionLength(0))), unit: "mg/dL")
                        Image(systemName: "equal")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        reading(mmol(mgdl), unit: "mmol/L")
                    }
                    .foregroundStyle(zone.color)
                    .animation(.snappy, value: mgdl)

                    Label(zone.name, systemImage: zone.symbol)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(zone.bandColor.gradient, in: .capsule)
                        .contentTransition(.interpolate)
                        .animation(.snappy, value: zone)

                    Slider(value: Binding { mgdl } set: { mgdl = $0.rounded() }, in: 40...400) {
                        Text("Glucose")
                    } minimumValueLabel: {
                        Image(systemName: "drop")
                    } maximumValueLabel: {
                        Image(systemName: "drop.fill")
                    }
                    .tint(zone.bandColor)
                    .accessibilityValue("\(Int(mgdl)) mg/dL, \(mmol(mgdl)) mmol/L")
                    .sensoryFeedback(.selection, trigger: zone)
                }
                .card()
                Text("Drag to convert. The color shows where the value falls on your own lines.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            GuideSection(title: "The Rule of Thumb") {
                HStack(spacing: 12) {
                    ruleTile("÷ 18", caption: "mg/dL to mmol/L")
                    ruleTile("× 18", caption: "mmol/L to mg/dL")
                }
                Text("The US mostly uses mg/dL. Canada, the UK, Australia and much of Europe use mmol/L. DiabetesCare stores mg/dL and converts for display, so switching units never changes your data.")
                    .fixedSize(horizontal: false, vertical: true)
            }

            GuideSection(title: "Numbers Worth Knowing") {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Text("mg/dL").frame(width: 44, alignment: .trailing)
                        Text("mmol/L").frame(width: 44, alignment: .trailing)
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
                    .accessibilityHidden(true)
                    ForEach(Array(landmarks.enumerated()), id: \.offset) { index, landmark in
                        if index > 0 { Divider() }
                        HStack {
                            Circle()
                                .fill(settings.zone(for: landmark.mgdl).bandColor)
                                .frame(width: 10, height: 10)
                                .accessibilityHidden(true)
                            Text(landmark.label)
                            Spacer()
                            Text("\(Int(landmark.mgdl))")
                                .monospacedDigit()
                                .frame(width: 44, alignment: .trailing)
                            Text(mmol(landmark.mgdl))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .frame(width: 44, alignment: .trailing)
                        }
                        .font(.subheadline)
                        .padding(.vertical, 10)
                        .accessibilityElement(children: .combine)
                    }
                }
                .card(padding: 14)
            }

            GuideRelatedTerms(termIDs: ["mg-dl-mmol-l", "blood-glucose", "target-range"])
        }
    }

    private func mmol(_ mgdl: Double) -> String {
        (mgdl / Self.factor).formatted(.number.precision(.fractionLength(1)))
    }

    private func reading(_ value: String, unit: String) -> some View {
        VStack(spacing: 0) {
            Text(value)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(unit)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func ruleTile(_ rule: String, caption: String) -> some View {
        VStack(spacing: 4) {
            Text(rule)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(Guide.units.gradient)
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .printSurface()
    }
}

#Preview {
    NavigationStack {
        UnitsGuideView()
            .glossaryDestinations()
    }
    .environment(SettingsStore())
}
