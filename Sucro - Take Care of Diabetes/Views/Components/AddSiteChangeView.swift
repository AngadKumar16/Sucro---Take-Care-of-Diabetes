//
//  AddSiteChangeView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import PhotosUI
import CoreData

struct AddSiteChangeView: View {
    @Environment(HomeViewModel.self) private var viewModel

    @State private var location: SiteLocation = .abdomenLeft
    @State private var timestamp = Date()
    @State private var notes = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?

    var body: some View {
        EntryForm(
            title: "Change Site",
            canSave: true,
            hasChanges: !notes.isEmpty || photoData != nil,
            onSave: save
        ) {
            SiteFields(location: $location, timestamp: $timestamp, notes: $notes)

            Section("Photo") {
                if let photoData, let image = UIImage(data: photoData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(.rect(cornerRadius: 8))
                        .accessibilityLabel("Site photo")
                }
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label(photoData == nil ? "Add Photo" : "Change Photo", systemImage: "photo")
                }
                if photoData != nil {
                    Button("Remove Photo", role: .destructive) {
                        photoItem = nil
                        photoData = nil
                    }
                }
            }
        }
        .onAppear { location = suggestedLocation }
        .onChange(of: photoItem) { _, item in
            Task { await loadPhoto(item) }
        }
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

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        // Re-encode so large HEIC originals don't bloat the store.
        photoData = image.jpegData(compressionQuality: 0.8)
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
