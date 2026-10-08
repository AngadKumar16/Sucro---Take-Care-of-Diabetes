//
//  EntryEditorView.swift
//  Sucro - Take Care of Diabetes
//
//  Picks the edit form for whatever kind of entry a draft holds.
//

import SwiftUI
import CoreData

struct EntryEditorView: View {
    let operation: DraftOperation<NSManagedObject>

    var body: some View {
        switch operation.draftObject {
        case let reading as GlucoseReading:
            EditGlucoseView(entry: reading, operation: operation)
        case let entry as CarbEntry:
            EditCarbView(entry: entry, operation: operation)
        case let entry as InsulinEntry:
            EditInsulinView(entry: entry, operation: operation)
        case let entry as ActivityEntry:
            EditActivityView(entry: entry, operation: operation)
        case let entry as SiteChange:
            EditSiteChangeView(entry: entry, operation: operation)
        default:
            ContentUnavailableView("Can't Edit This Entry", systemImage: "pencil.slash")
        }
    }
}
