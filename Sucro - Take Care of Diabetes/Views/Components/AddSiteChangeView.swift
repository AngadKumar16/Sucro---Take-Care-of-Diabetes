//
//  AddSiteChangeView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct AddSiteChangeView: View {
    @Environment(HomeViewModel.self) private var viewModel

    @State private var location: SiteLocation = .abdomenLeft
    @State private var timestamp = Date()
    @State private var notes = ""
    @State private var photoData: Data?
    @State private var side: BodySide = .front

    var body: some View {
        EntryForm(
            title: "Change Site",
            canSave: true,
            hasChanges: !notes.isEmpty || photoData != nil,
            onSave: save
        ) {
            Section {
                VStack(spacing: 12) {
                    Picker("Side", selection: $side) {
                        ForEach(BodySide.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    BodyMap(side: side, current: SiteLocation(stored: viewModel.lastSiteChange?.location),
                            history: viewModel.siteHistory, suggested: suggestedLocation, selection: $location)
                        .frame(height: 250)
                    BodyMapKey()
                }
                .padding(.vertical, 6)
            } footer: {
                Text("Tap a site. Green is the one that has rested longest.")
            }
            .listRowBackground(Theme.card)
            SiteFields(location: $location, timestamp: $timestamp, notes: $notes)
            SitePhotoSection(photo: $photoData)
        }
        .onAppear {
            location = suggestedLocation
            side = BodySide.showing(location)
        }
        .onChange(of: location) { _, new in
            if new.point(on: side) == nil { side = BodySide.showing(new) }
        }
    }

    /// The site that has rested longest, so the same spot isn't reused
    /// by accident.
    private var suggestedLocation: SiteLocation {
        SiteLocation.suggested(current: SiteLocation(stored: viewModel.lastSiteChange?.location), history: viewModel.siteHistory)
    }

    private func save() -> Bool {
        let siteChange = SiteChange(context: viewModel.viewContext)
        siteChange.id = UUID()
        siteChange.timestamp = timestamp
        siteChange.location = location.rawValue
        siteChange.notes = notes.isEmpty ? nil : notes
        siteChange.siteType = "Infusion"
        siteChange.deviceType = "Pump"
        siteChange.photo = photoData
        viewModel.save()
        // Refreshing also schedules the reminder for the next change.
        viewModel.fetchLatestData()
        return true
    }
}

#Preview {
    AddSiteChangeView()
        .environment(HomeViewModel(context: PersistenceController.preview.container.viewContext))
}
