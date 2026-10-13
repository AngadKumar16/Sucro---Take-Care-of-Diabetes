//
//  GlucoseWidget.swift
//  DiabetesCareWidgets
//
//  Latest glucose, its trend and age on the Home Screen and Lock Screen.
//  Medium shows the last three hours; accessory sizes fit the Lock Screen
//  and the watch face.
//

import Charts
import SwiftUI
import WidgetKit

struct GlucoseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GlucoseWidget", provider: GlanceProvider()) { entry in
            GlucoseWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetBackground() }
                .widgetURL(URL(string: "diabetescare://trends"))
        }
        .configurationDisplayName("Glucose")
        .description("Your latest glucose, trend and how long ago it was.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct WidgetBackground: View {
    var body: some View {
        LinearGradient(colors: [Color(red: 0.97, green: 0.96, blue: 0.93), Color(red: 0.93, green: 0.91, blue: 0.87)],
                       startPoint: .top, endPoint: .bottom)
    }
}

struct GlucoseWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: GlanceEntry

    var body: some View {
        if let snapshot = entry.snapshot, let latest = snapshot.latest {
            let stale = snapshot.isStale(at: entry.date)
            let color = stale ? Color.secondary : snapshot.zone(latest.mgdl).color
            switch family {
            case .accessoryCircular:
                Gauge(value: min(max(latest.mgdl, 40), 300), in: 40...300) {
                    Image(systemName: "drop.fill")
                } currentValueLabel: {
                    Text(snapshot.value(latest.mgdl))
                        .font(.system(.body, design: .rounded, weight: .bold))
                }
                .gaugeStyle(.accessoryCircular)
                .widgetAccentable()
            case .accessoryInline:
                Text("\(Image(systemName: snapshot.trendSymbol ?? "drop")) \(snapshot.value(latest.mgdl)) \(snapshot.unit) · \(latest.date, style: .relative)")
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text(snapshot.value(latest.mgdl))
                            .font(.system(.title2, design: .rounded, weight: .bold))
                        if let symbol = snapshot.trendSymbol, !stale { Image(systemName: symbol).font(.headline) }
                        Spacer(minLength: 0)
                    }
                    Text(latest.date, style: .relative)
                        .font(.caption2)
                    Sparkline(snapshot: snapshot, color: .primary)
                        .frame(height: 16)
                }
                .widgetAccentable()
            case .systemMedium:
                HStack(spacing: 14) {
                    ReadingBlock(snapshot: snapshot, latest: latest, color: color, stale: stale)
                    Sparkline(snapshot: snapshot, color: color, showsTarget: true)
                }
            default:
                ReadingBlock(snapshot: snapshot, latest: latest, color: color, stale: stale)
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "drop")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("No readings yet")
                    .font(.headline)
                Text("Open DiabetesCare to log one.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct ReadingBlock: View {
    let snapshot: GlanceSnapshot
    let latest: GlanceSnapshot.Point
    let color: Color
    let stale: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(stale ? "Last reading" : snapshot.zone(latest.mgdl).name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(snapshot.value(latest.mgdl))
                    .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(color)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText(value: latest.mgdl))
                if let symbol = snapshot.trendSymbol, !stale {
                    Image(systemName: symbol)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(color)
                }
            }
            Text(snapshot.unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(latest.date, style: .relative)
                .font(.caption)
                .foregroundStyle(stale ? .orange : .secondary)
            if snapshot.insulinOnBoard >= 0.05 {
                Text("\(snapshot.insulinOnBoard.formatted(.number.precision(.fractionLength(1)))) U active")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Sparkline: View {
    let snapshot: GlanceSnapshot
    let color: Color
    var showsTarget = false

    var body: some View {
        Chart {
            if showsTarget {
                RectangleMark(yStart: .value("Low", snapshot.display(snapshot.targetLow)), yEnd: .value("High", snapshot.display(snapshot.targetHigh)))
                    .foregroundStyle(.green.opacity(0.12))
            }
            ForEach(snapshot.recent, id: \.date) { point in
                LineMark(x: .value("Time", point.date), y: .value("Glucose", snapshot.display(point.mgdl)))
                    .foregroundStyle(color)
                    .interpolationMethod(.monotone)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: snapshot.display(40)...snapshot.display(max(260, (snapshot.recent.map(\.mgdl).max() ?? 0) + 10)))
    }
}

#Preview(as: .systemMedium) {
    GlucoseWidget()
} timeline: {
    GlanceEntry(date: .now, snapshot: .placeholder)
}
