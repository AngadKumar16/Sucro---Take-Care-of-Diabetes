//
//  SitePicker.swift
//  DiabetesCare
//
//  Picks an infusion site on the body map, used by Change Site and Edit
//  Site Change. The list picker under the map reaches every site,
//  including "Other", without aiming at the drawing.
//

import SwiftUI

struct SitePicker: View {
    @Binding var location: SiteLocation
    let current: SiteLocation?
    let history: [SiteLocation: Date]
    var suggested: SiteLocation?

    @State private var side: BodySide = .front

    var body: some View {
        Section {
            VStack(spacing: 12) {
                Picker("Side", selection: $side) {
                    ForEach(BodySide.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                BodyMap(side: side, current: current, history: history, suggested: suggested, selection: $location)
                    .frame(height: 250)
                BodyMapKey()
            }
            .padding(.vertical, 6)
            Picker("Site", selection: $location) {
                ForEach(SiteLocation.allCases, id: \.self) { site in
                    Text(site.spokenName).tag(site)
                }
            }
            LabeledContent("Change Every", value: "\(location.rotationDays) days")
        } footer: {
            Text(suggested == nil
                 ? "Tap a site on the map or pick one from the list."
                 : "Tap a site. Green is the one that has rested longest. You'll get a reminder when this site is due.")
        }
        .listRowBackground(Theme.card)
        .onAppear { side = BodySide.showing(location) }
        .onChange(of: location) { _, new in
            if new.point(on: side) == nil { side = BodySide.showing(new) }
        }
    }
}
