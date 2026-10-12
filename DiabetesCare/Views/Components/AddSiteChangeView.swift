//
//  AddSiteChangeView.swift
//  DiabetesCare
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

    var body: some View {
        EntryForm(
            title: "Change Site",
            canSave: true,
            hasChanges: !notes.isEmpty || photoData != nil,
            onSave: save
        ) {
            SitePicker(
                location: $location,
                current: SiteLocation(stored: viewModel.lastSiteChange?.location),
                history: viewModel.siteHistory,
                suggested: suggestedLocation
            )
            TimeAndNotesSections(timestamp: $timestamp, notes: $notes, timeLabel: "Changed")
            SitePhotoSection(photo: $photoData)
        }
        .onAppear {
            location = suggestedLocation
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
        guard viewModel.save() else {
            viewModel.viewContext.delete(siteChange)
            return false
        }
        // Refreshing also schedules the reminder for the next change.
        viewModel.fetchLatestData()
        return true
    }
}

#Preview {
    AddSiteChangeView()
        .environment(HomeViewModel(context: PersistenceController.preview.container.viewContext))
}
