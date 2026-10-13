//
//  KidHelpWidget.swift
//  DiabetesCareWidgets
//
//  "Feeling off?" for a kid's Home Screen: one tap logs 15 g of fast sugar
//  and starts the recheck countdown; another opens Get Help.
//

import AppIntents
import SwiftUI
import WidgetKit

struct KidHelpWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "KidHelpWidget", provider: GlanceProvider()) { entry in
            KidHelpWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName("Feeling Off?")
        .description("Log fast sugar for a low in one tap, or get help.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct KidHelpWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: GlanceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Feeling off?")
                    .font(.headline)
                Spacer()
                if let snapshot = entry.snapshot, let latest = snapshot.latest, !snapshot.isStale(at: entry.date) {
                    Text(snapshot.value(latest.mgdl))
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(snapshot.zone(latest.mgdl).color)
                }
            }
            if let recheck = entry.snapshot?.lowRecheckAt, recheck > entry.date {
                Label {
                    Text("Check again \(recheck, style: .timer)")
                } icon: {
                    Image(systemName: "timer")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)
            }
            Spacer(minLength: 0)
            let layout = family == .systemMedium ? AnyLayout(HStackLayout(spacing: 8)) : AnyLayout(VStackLayout(spacing: 6))
            layout {
                Button(intent: LogFastSugarIntent(grams: 15)) {
                    Label("Had 15 g sugar", systemImage: "cube.fill")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .tint(.orange)
                Link(destination: URL(string: "diabetescare://get-help")!) {
                    Label("Get Help", systemImage: "hand.raised.fill")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 28)
                        .background(.green.opacity(0.2), in: .capsule)
                }
            }
        }
    }
}

#Preview(as: .systemSmall) {
    KidHelpWidget()
} timeline: {
    GlanceEntry(date: .now, snapshot: .placeholder)
}
