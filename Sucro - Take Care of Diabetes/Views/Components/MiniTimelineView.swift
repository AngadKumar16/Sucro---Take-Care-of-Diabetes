//
//  MiniTimelineView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData
import Charts

/// The last few hours of glucose on Today, with logged events marked at
/// the time they happened. Tapping it opens Trends.
struct MiniTimelineView: View {
    @Environment(SettingsStore.self) private var settings
    let glucoseReadings: [GlucoseSample]
    let events: [TimelineEvent]
    /// How far back the chart reaches, in seconds.
    let window: TimeInterval
    let onExpand: () -> Void

    var body: some View {
        Button(action: onExpand) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Last \(Int(window / 3600)) Hours")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }

                // Re-render each minute so the window keeps sliding.
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    if glucoseReadings.isEmpty {
                        Text("No readings in the last \(Int(window / 3600)) hours.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 80)
                    } else {
                        chart(now: context.date)
                    }
                }
            }
            .card()
            .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Opens Trends")
        .accessibilityAddTraits(.isButton)
    }

    private func chart(now: Date) -> some View {
        let start = now.addingTimeInterval(-window)
        let visibleEvents = events.filter { $0.timestamp >= start }
        let highest = glucoseReadings.map(\.mgdl).max() ?? 0
        let yTop = settings.displayGlucose(max(300, highest + 20))
        // Room under the glucose line for the event markers.
        let yBottom = settings.displayGlucose(10)
        let eventY = settings.displayGlucose(28)

        return Chart {
            RectangleMark(
                xStart: .value("Start", start),
                xEnd: .value("End", now),
                yStart: .value("Target low", settings.displayGlucose(settings.targetLow)),
                yEnd: .value("Target high", settings.displayGlucose(settings.targetHigh))
            )
            .foregroundStyle(.green.opacity(0.12))

            // Events sit along the bottom edge at the time they happened.
            ForEach(visibleEvents) { event in
                PointMark(
                    x: .value("Time", event.timestamp),
                    y: .value("Event", eventY)
                )
                .symbol {
                    Image(systemName: event.icon)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(event.color, in: .circle)
                }
            }

            ForEach(glucoseReadings, id: \.date) { reading in
                LineMark(
                    x: .value("Time", reading.date),
                    y: .value("Glucose", settings.displayGlucose(reading.mgdl))
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .interpolationMethod(.monotone)

                PointMark(
                    x: .value("Time", reading.date),
                    y: .value("Glucose", settings.displayGlucose(reading.mgdl))
                )
                .foregroundStyle(settings.zone(for: reading.mgdl).color)
                .symbolSize(30)
            }
        }
        .chartXScale(domain: start...now, range: .plotDimension(endPadding: 28))
        .chartYScale(domain: yBottom...yTop)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 2)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [settings.targetLow, settings.targetHigh].map(settings.displayGlucose)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(settings.glucoseUnit == "mmol/L" ? v.formatted(.number.precision(.fractionLength(1))) : "\(Int(v))")
                    }
                }
            }
        }
        .frame(height: 140)
    }

    private var accessibilitySummary: String {
        let hours = Int(window / 3600)
        guard let latest = glucoseReadings.last else {
            return "Glucose chart, last \(hours) hours. No readings."
        }
        let values = glucoseReadings.map(\.mgdl)
        return "Glucose chart, last \(hours) hours. \(glucoseReadings.count) readings, from \(settings.formattedGlucose(values.min() ?? 0)) to \(settings.formattedGlucose(values.max() ?? 0)). Latest \(settings.formattedGlucose(latest.mgdl))."
    }
}

#Preview {
    MiniTimelineView(
        glucoseReadings: [
            GlucoseSample(date: Date().addingTimeInterval(-5.5 * 3600), mgdl: 95),
            GlucoseSample(date: Date().addingTimeInterval(-5 * 3600), mgdl: 120),
            GlucoseSample(date: Date().addingTimeInterval(-4 * 3600), mgdl: 190),
            GlucoseSample(date: Date().addingTimeInterval(-3 * 3600), mgdl: 110),
            GlucoseSample(date: Date().addingTimeInterval(-2 * 3600), mgdl: 65),
            GlucoseSample(date: Date().addingTimeInterval(-1 * 3600), mgdl: 98),
            GlucoseSample(date: Date().addingTimeInterval(0 * 3600), mgdl: 104)
        ],
        events: [
            TimelineEvent(type: .meal, timestamp: Date().addingTimeInterval(-4.2 * 3600), glucoseValue: 140, title: "Lunch", subtitle: "Sandwich and apple"),
            TimelineEvent(type: .bolus, timestamp: Date().addingTimeInterval(-4.5 * 3600), glucoseValue: 145, title: "Bolus", subtitle: "5 units"),
            TimelineEvent(type: .activity, timestamp: Date().addingTimeInterval(-2 * 3600), glucoseValue: 110, title: "Walk", subtitle: "30 minutes")
        ],
        window: 6 * 3600,
        onExpand: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
    .environment(SettingsStore())
}
