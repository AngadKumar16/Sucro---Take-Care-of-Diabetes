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

    var body: some View {
        Button(action: onTap) {
            // Re-render each minute so "5 min ago" and the stale styling stay
            // current without new data.
            TimelineView(.periodic(from: .now, by: 60)) { context in
                GlucoseHeroContent(reading: glucoseReading, insulinOnBoard: insulinOnBoard, now: context.date)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(glucoseReading == nil)
        .accessibilityHint(glucoseReading == nil ? "" : "Opens the glucose chart")
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
        GlucoseHeroView(glucoseReading: nil, insulinOnBoard: 0, onTap: {})
        GlucoseHeroView(glucoseReading: fresh, insulinOnBoard: 2.5, onTap: {})
        GlucoseHeroView(glucoseReading: old, insulinOnBoard: 0, onTap: {})
    }
    .padding()
    .environment(SettingsStore())
}
