//
//  GlucoseHeroContent.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// The latest reading, its age, trend and the IOB estimate, as of `now`.
struct GlucoseHeroContent: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    /// Observed so an edit to this reading (from Log, say) redraws it.
    @ObservedObject var reading: GlucoseReading
    let insulinOnBoard: Double
    let now: Date

    /// After this long the value is greyed out, since it may not reflect
    /// current glucose.
    private static let staleAfter: TimeInterval = 15 * 60

    @ScaledMetric(relativeTo: .largeTitle) private var valueSize = 64
    @ScaledMetric(relativeTo: .title) private var arrowSize = 32

    private var isStale: Bool {
        guard let timestamp = reading.timestamp else { return true }
        return now.timeIntervalSince(timestamp) > Self.staleAfter
    }

    private var zone: GlucoseZone {
        settings.zone(for: reading.value)
    }

    /// A trend only means something for a recent reading.
    private var trend: GlucoseTrend? {
        isStale ? nil : GlucoseTrend(stored: reading.trend)
    }

    private var valueColor: Color {
        isStale ? .secondary : zone.color
    }

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(settings.glucoseValueString(reading.value))
                        .font(.system(size: valueSize, weight: .bold, design: .rounded))
                        .foregroundStyle(valueColor)

                    if let trend {
                        Image(systemName: trend.arrowSymbol)
                            .font(.system(size: arrowSize, weight: .semibold))
                            .foregroundStyle(valueColor)
                    }

                    Text(settings.glucoseUnit)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                // Color alone shouldn't carry the meaning.
                if differentiateWithoutColor, !isStale {
                    Text(zone.name)
                        .font(.headline)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(readingDescription)

            if let timestamp = reading.timestamp {
                Text(timestampText(timestamp))
                    .font(.subheadline)
                    .foregroundStyle(isStale ? .orange : .secondary)
            }

            InsulinOnBoardLabel(units: insulinOnBoard)
        }
    }

    private var readingDescription: String {
        var parts = [settings.formattedGlucose(reading.value)]
        if !isStale { parts.append(zone.name) }
        if let trend { parts.append(trend.description) }
        return parts.joined(separator: ", ")
    }

    private func timestampText(_ timestamp: Date) -> String {
        let time = timestamp.formatted(date: .omitted, time: .shortened)
        if now.timeIntervalSince(timestamp) < 60 {
            return "Just now · \(time)"
        }
        let relative = timestamp.formatted(.relative(presentation: .named, unitsStyle: .abbreviated))
        return "\(relative) · \(time)"
    }
}
