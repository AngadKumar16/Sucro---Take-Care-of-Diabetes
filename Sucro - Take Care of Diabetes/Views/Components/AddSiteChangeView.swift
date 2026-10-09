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

    var body: some View {
        EntryForm(
            title: "Change Site",
            canSave: true,
            hasChanges: !notes.isEmpty || photoData != nil,
            onSave: save
        ) {
            SiteFields(location: $location, timestamp: $timestamp, notes: $notes)
            SitePhotoSection(photo: $photoData)
        }
        .onAppear { location = suggestedLocation }
    }

    /// The next site in the rotation after the current one, so the same
    /// spot isn't reused by accident.
    private var suggestedLocation: SiteLocation {
        let rotation = SiteLocation.allCases.filter { $0 != .other }
        guard let current = SiteLocation(stored: viewModel.lastSiteChange?.location),
              let index = rotation.firstIndex(of: current) else {
            return .abdomenLeft
        }
        return rotation[(index + 1) % rotation.count]
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
