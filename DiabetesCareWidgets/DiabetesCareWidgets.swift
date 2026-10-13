//
//  DiabetesCareWidgets.swift
//  DiabetesCareWidgets
//
//  Everything DiabetesCare shows outside the app: glucose widgets for the
//  Home and Lock Screen, a kid's "Feeling off?" widget with buttons, the
//  low-treatment Live Activity, and Control Center buttons.
//

import SwiftUI
import WidgetKit

@main
struct DiabetesCareWidgets: WidgetBundle {
    var body: some Widget {
        GlucoseWidget()
        KidHelpWidget()
        LowTreatmentLiveActivity()
        LogCarbsControl()
        LogGlucoseControl()
        GetHelpControl()
    }
}

// MARK: - Timeline

struct GlanceEntry: TimelineEntry {
    let date: Date
    let snapshot: GlanceSnapshot?
}

struct GlanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> GlanceEntry {
        GlanceEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (GlanceEntry) -> Void) {
        completion(GlanceEntry(date: .now, snapshot: context.isPreview ? .placeholder : (GlanceSnapshot.load() ?? .placeholder)))
    }

    /// Now, and the moment the reading goes stale, so the widget greys it
    /// out on time. The app reloads widgets whenever anything changes.
    func getTimeline(in context: Context, completion: @escaping (Timeline<GlanceEntry>) -> Void) {
        let now = Date()
        let snapshot = GlanceSnapshot.load()
        var entries = [GlanceEntry(date: now, snapshot: snapshot)]
        if let latest = snapshot?.latest {
            let staleAt = latest.date.addingTimeInterval(GlanceSnapshot.staleAfter)
            if staleAt > now { entries.append(GlanceEntry(date: staleAt, snapshot: snapshot)) }
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(30 * 60))))
    }
}
