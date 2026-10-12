//
//  EditSiteChangeView.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI
import CoreData

struct EditSiteChangeView: View {
    let entry: SiteChange
    let operation: DraftOperation<NSManagedObject>

    @State private var location: SiteLocation = .other
    @State private var timestamp = Date()
    @State private var notes = ""
    @State private var photo: Data?
    @State private var original: [AnyHashable] = []

    @FetchRequest(sortDescriptors: [SortDescriptor(\SiteChange.timestamp, order: .reverse)])
    private var siteChanges: FetchedResults<SiteChange>

    private var current: [AnyHashable] { [location, timestamp, notes, photo] }

    var body: some View {
        EntryForm(
            title: "Edit Site Change",
            canSave: true,
            hasChanges: !original.isEmpty && current != original,
            onSave: save,
            onCancel: operation.cancel
        ) {
            SitePicker(location: $location, current: nil, history: otherSitesLastUsed)
            TimeAndNotesSections(timestamp: $timestamp, notes: $notes, timeLabel: "Changed")
            SitePhotoSection(photo: $photo)
        }
        .onAppear(perform: load)
    }

    /// When each site was last used, not counting the change being edited.
    private var otherSitesLastUsed: [SiteLocation: Date] {
        SiteRotation.lastUsed(siteChanges.filter { $0.objectID != entry.objectID }.compactMap(\.rotationChange))
    }

    private func load() {
        guard original.isEmpty else { return }
        location = SiteLocation(stored: entry.location) ?? .other
        timestamp = entry.timestamp ?? Date()
        notes = entry.notes ?? ""
        photo = entry.photo
        original = current
    }

    private func save() -> Bool {
        entry.location = location.rawValue
        entry.timestamp = timestamp
        entry.notes = notes.isEmpty ? nil : notes
        entry.photo = photo
        return operation.save()
    }
}
