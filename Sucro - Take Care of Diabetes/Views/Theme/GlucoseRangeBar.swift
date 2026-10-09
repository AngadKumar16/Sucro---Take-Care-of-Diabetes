//
//  GlucoseRangeBar.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// The five glucose zones laid out on one bar, sized by the user's
/// thresholds, with each threshold labeled. Low-side labels sit above the
/// bar and high-side labels below, so close lines like 55 and 70 never
/// overlap.
struct GlucoseRangeBar: View {
    @Environment(SettingsStore.self) private var settings
    let thresholds: GlucoseThresholds
    var height: CGFloat = 14

    /// The mg/dL span the bar covers.
    static let scale: ClosedRange<Double> = 40...400

    private var edges: [(zone: GlucoseZone, from: Double, to: Double)] {
        let t = thresholds
        return [
            (.urgentLow, Self.scale.lowerBound, t.urgentLow),
            (.low, t.urgentLow, t.targetLow),
            (.inRange, t.targetLow, t.targetHigh),
            (.high, t.targetHigh, t.urgentHigh),
            (.urgentHigh, t.urgentHigh, Self.scale.upperBound)
        ]
    }

    private var lines: [(value: Double, above: Bool)] {
        [(thresholds.urgentLow, true), (thresholds.targetLow, false),
         (thresholds.targetHigh, true), (thresholds.urgentHigh, false)]
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let labelY = (above: CGFloat(8), below: CGFloat(8 + 16 + height + 8))
            ZStack(alignment: .topLeading) {
                HStack(spacing: 2) {
                    ForEach(edges, id: \.zone) { edge in
                        Rectangle()
                            .fill(edge.zone.bandColor.gradient)
                            .frame(width: max(0, x(edge.to, width) - x(edge.from, width) - 2))
                    }
                }
                .frame(width: width, height: height, alignment: .leading)
                .clipShape(.capsule)
                .offset(y: 16 + 4)

                ForEach(lines, id: \.value) { line in
                    Text(settings.glucoseValueString(line.value))
                        .font(Theme.readout(.caption2, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .fixedSize()
                        .position(x: min(max(x(line.value, width), 14), width - 14),
                                  y: line.above ? labelY.above : labelY.below)
                }
            }
        }
        .frame(height: 16 + 4 + height + 4 + 16)
        .animation(.snappy, value: thresholds)
        .accessibilityElement()
        .accessibilityLabel("Glucose ranges")
        .accessibilityValue("In range from \(settings.formattedGlucose(thresholds.targetLow)) to \(settings.formattedGlucose(thresholds.targetHigh))")
    }

    private func x(_ mgdl: Double, _ width: CGFloat) -> CGFloat {
        let span = Self.scale.upperBound - Self.scale.lowerBound
        let clamped = min(max(mgdl, Self.scale.lowerBound), Self.scale.upperBound)
        return width * (clamped - Self.scale.lowerBound) / span
    }
}

#Preview {
    GlucoseRangeBar(thresholds: .standard)
        .padding()
        .environment(SettingsStore())
}
