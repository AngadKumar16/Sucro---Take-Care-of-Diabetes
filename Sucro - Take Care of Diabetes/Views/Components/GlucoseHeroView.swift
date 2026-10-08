//
//  GlucoseHeroView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct GlucoseHeroView: View {
    let glucoseReading: GlucoseReading?
    let insulinOnBoard: Double
    let onTap: () -> Void
    let onLogGlucose: () -> Void

    var body: some View {
        if glucoseReading == nil {
            emptyState
        } else {
            Button(action: onTap) {
                // Re-render each minute so "5 min ago" and the stale styling stay
                // current without new data.
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    GlucoseHeroContent(reading: glucoseReading, insulinOnBoard: insulinOnBoard, now: context.date)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
                .contentShape(.rect(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens Trends")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "drop")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("No Readings Yet")
                .font(.headline)
            Text("Log a fingerstick reading to see it here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Log Glucose", systemImage: "plus", action: onLogGlucose)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let fresh = GlucoseReading(context: context)
    fresh.value = 104
    fresh.timestamp = Date().addingTimeInterval(-120)
    fresh.trend = GlucoseTrend.rising.rawValue
    let old = GlucoseReading(context: context)
    old.value = 62
    old.timestamp = Date().addingTimeInterval(-3 * 3600)
    return VStack(spacing: 20) {
        GlucoseHeroView(glucoseReading: nil, insulinOnBoard: 0, onTap: {}, onLogGlucose: {})
        GlucoseHeroView(glucoseReading: fresh, insulinOnBoard: 2.5, onTap: {}, onLogGlucose: {})
        GlucoseHeroView(glucoseReading: old, insulinOnBoard: 0, onTap: {}, onLogGlucose: {})
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    .environment(SettingsStore())
}
