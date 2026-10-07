//
//  StoreErrorView.swift
//  Sucro - Take Care of Diabetes
//
//  Shown instead of the app when the Core Data store can't be opened.
//

import SwiftUI

struct StoreErrorView: View {
    @Environment(PersistenceController.self) private var persistence
    let error: Error

    @State private var confirmErase = false

    var body: some View {
        ContentUnavailableView {
            Label("Can't Open Your Data", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text("Something went wrong opening the database on this phone. Nothing has been deleted. If your storage is full, free up some space and try again.")
        } actions: {
            Button("Try Again", action: persistence.retry)
                .buttonStyle(.borderedProminent)

            Button("Erase Data and Start Over", role: .destructive, action: askToErase)

            DisclosureGroup("Error details") {
                Text(error.localizedDescription)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.footnote)
        }
        .alert("Erase all data on this phone?", isPresented: $confirmErase) {
            Button("Erase", role: .destructive, action: persistence.resetStore)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your glucose, insulin, carb, activity and site history will be deleted. This can't be undone. Anything already saved to Apple Health stays there.")
        }
    }

    private func askToErase() {
        confirmErase = true
    }
}

#Preview {
    StoreErrorView(error: NSError(domain: NSCocoaErrorDomain, code: 134110))
        .environment(PersistenceController(inMemory: true))
}
