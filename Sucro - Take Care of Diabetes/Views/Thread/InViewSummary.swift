//
//  InViewSummary.swift
//  Sucro - Take Care of Diabetes
//
//  Describes whatever stretch of the thread is on screen. Scroll or zoom
//  and the numbers follow, so the thread doubles as Trends.
//

import SwiftUI

struct InViewSummary: View {
    @Environment(SettingsStore.self) private var settings
    let window: ThreadWindow
    let samples: [GlucoseSample]
    let events: [TimelineEvent]

    private var visibleSamples: [GlucoseSample] { samples.filter { window.contains($0.date) } }
    private var visibleEvents: [TimelineEvent] { events.filter { window.contains($0.timestamp) } }

    var body: some View {
        let stats = GlucoseCalculator.calculateStatistics(samples: visibleSamples, thresholds: settings.thresholds)
        let count = visibleSamples.count

        VStack(alignment: .leading, spacing: 10) {
            Text("In view · \(rangeText)")
                .instrumentLabel()
                .accessibilityAddTraits(.isHeader)

            if count == 0 {
                Text("No readings in this stretch.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(alignment: .top, spacing: 0) {
                    cell("In range", percent(stats.timeInRange.percentage), "%", color: GlucoseZone.inRange.color)
                    cell("Low", percent(stats.timeBelowRange.percentage), "%", color: stats.timeBelowRange.percentage > 0 ? GlucoseZone.low.color : nil)
                    cell("Average", settings.glucoseValueString(stats.average), settings.glucoseUnit, color: nil)
                    cell("Readings", "\(count)", nil, color: nil)
                }
                .fixedSize(horizontal: false, vertical: true)
            }

            if !visibleEvents.isEmpty {
                Text(eventCounts)
                    .font(Theme.readout(.caption))
                    .foregroundStyle(.secondary)
            }
        }
        .card()
        .animation(.snappy, value: window)
    }

    private var rangeText: String {
        // The window can reach past now to catch fresh entries; say "now".
        let end = min(window.end, Date())
        let sameDay = Calendar.current.isDate(window.start, inSameDayAs: end)
        let start = window.start.formatted(.dateTime.month(.abbreviated).day().hour())
        let endText = sameDay
            ? end.formatted(.dateTime.hour())
            : end.formatted(.dateTime.month(.abbreviated).day().hour())
        return "\(start) – \(endText)"
    }

    private var eventCounts: String {
        let meals = visibleEvents.filter { $0.type == .meal }.count
        let doses = visibleEvents.filter { $0.type == .bolus }.count
        let activity = visibleEvents.filter { $0.type == .activity }.count
        let sites = visibleEvents.filter { $0.type == .siteChange }.count
        return [
            plural(meals, "meal"), plural(doses, "dose"),
            plural(activity, "activity", "activities"), plural(sites, "site change")
        ].compactMap { $0 }.joined(separator: " · ")
    }

    private func plural(_ count: Int, _ one: String, _ many: String? = nil) -> String? {
        guard count > 0 else { return nil }
        return "\(count) \(count == 1 ? one : (many ?? one + "s"))"
    }

    private func percent(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }

    private func cell(_ title: String, _ value: String, _ unit: String?, color: Color?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .instrumentLabel()
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(Theme.readout(.title3, weight: .semibold))
                    .foregroundStyle(color ?? .primary)
                    .contentTransition(.numericText())
                if let unit {
                    Text(unit)
                        .font(Theme.readout(.caption2))
                        .foregroundStyle(.secondary)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
