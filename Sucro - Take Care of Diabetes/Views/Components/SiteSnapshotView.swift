//
//  SiteSnapshotView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

/// Your sites on a body map: where the current site is, how old it is,
/// when it's due, and which site has rested longest. Tapping it logs a
/// new site change.
struct SiteSnapshotView: View {
    let lastSiteChange: SiteChange?
    var history: [SiteLocation: Date] = [:]
    let onChangeSite: () -> Void

    var body: some View {
        let current = SiteLocation(stored: lastSiteChange?.location)
        let next = SiteLocation.suggested(current: current, history: history)

        VStack(alignment: .leading, spacing: 8) {
            CardHeader("Your sites")

            Button(action: onChangeSite) {
                HStack(alignment: .center, spacing: 16) {
                    BodyMap(side: BodySide.showing(current), current: current, history: history, suggested: next)
                        .frame(width: 92)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 10) {
                        if let siteChange = lastSiteChange, siteChange.timestamp != nil {
                            TimelineView(.periodic(from: .now, by: 60)) { context in
                                CurrentSiteRow(siteChange: siteChange, now: context.date)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("No site logged")
                                    .font(.system(.headline, design: .serif, weight: .semibold))
                                Text("Log your next site change to get a reminder when it's due.")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.soft)
                            }
                        }
                        Rectangle().fill(Theme.rule).frame(height: 1)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Next: \(next.spokenName.lowercased())")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.green)
                            Text(restedText(next))
                                .font(.footnote)
                                .foregroundStyle(Theme.soft)
                        }
                        BodyMapKey()
                    }
                }
                .card()
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Logs a site change")
        }
    }

    private func restedText(_ site: SiteLocation) -> String {
        guard let used = history[site] else { return "Not used yet" }
        let days = Calendar.current.dateComponents([.day], from: used, to: .now).day ?? 0
        return days == 1 ? "Rested 1 day" : "Rested \(days) days"
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let siteChange = SiteChange(context: context)
    siteChange.location = "Abdomen Left"
    siteChange.timestamp = Date().addingTimeInterval(-86400)
    return VStack(spacing: 20) {
        SiteSnapshotView(lastSiteChange: siteChange, history: [.abdomenLeft: .now, .armLeft: .now.addingTimeInterval(-3 * 86400)], onChangeSite: {})
        SiteSnapshotView(lastSiteChange: nil, onChangeSite: {})
    }
    .padding()
    .instrumentBackground()
    .environment(SettingsStore())
}
