//
//  WatchComplications.swift
//  DiabetesCare Watch Complications
//
//  Glucose on the watch face: a gauge, a line with the trend, or a word.
//  Reads the snapshot the watch app saved from the phone.
//

import SwiftUI
import WidgetKit

@main
struct WatchComplications: WidgetBundle {
    var body: some Widget {
        GlucoseComplication()
    }
}

struct ComplicationEntry: TimelineEntry {
    let date: Date
    let snapshot: GlanceSnapshot?
}

struct ComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComplicationEntry { ComplicationEntry(date: .now, snapshot: .placeholder) }

    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {
        completion(ComplicationEntry(date: .now, snapshot: GlanceSnapshot.load() ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
        let now = Date()
        let snapshot = GlanceSnapshot.load()
        var entries = [ComplicationEntry(date: now, snapshot: snapshot)]
        if let latest = snapshot?.latest, latest.date.addingTimeInterval(GlanceSnapshot.staleAfter) > now {
            entries.append(ComplicationEntry(date: latest.date.addingTimeInterval(GlanceSnapshot.staleAfter), snapshot: snapshot))
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(30 * 60))))
    }
}

struct GlucoseComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GlucoseComplication", provider: ComplicationProvider()) { entry in
            ComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Glucose")
        .description("Your latest glucose and trend.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

struct ComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ComplicationEntry

    var body: some View {
        if let snapshot = entry.snapshot, let latest = snapshot.latest {
            let stale = snapshot.isStale(at: entry.date)
            switch family {
            case .accessoryCircular:
                Gauge(value: min(max(latest.mgdl, 40), 300), in: 40...300) {
                    Image(systemName: "drop.fill")
                } currentValueLabel: {
                    Text(snapshot.value(latest.mgdl))
                }
                .gaugeStyle(.accessoryCircular)
                .tint(stale ? .gray : snapshot.zone(latest.mgdl).color)
            case .accessoryCorner:
                Text(snapshot.value(latest.mgdl))
                    .widgetLabel {
                        Text(latest.date, style: .relative)
                    }
            case .accessoryInline:
                Text("\(Image(systemName: snapshot.trendSymbol ?? "drop")) \(snapshot.value(latest.mgdl)) · \(latest.date, style: .relative)")
            default:
                VStack(alignment: .leading) {
                    HStack {
                        Text(snapshot.value(latest.mgdl))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(stale ? .gray : snapshot.zone(latest.mgdl).color)
                        if let symbol = snapshot.trendSymbol, !stale { Image(systemName: symbol) }
                    }
                    Text("\(snapshot.unit) · \(latest.date, style: .relative)")
                        .font(.caption2)
                }
            }
        } else {
            Image(systemName: "drop")
        }
    }
}
