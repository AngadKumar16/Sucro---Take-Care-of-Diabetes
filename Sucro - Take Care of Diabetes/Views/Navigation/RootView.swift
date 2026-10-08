//
//  RootView.swift
//  Sucro - Take Care of Diabetes
//
//  Decides what the app shows first: the store error screen if the database
//  couldn't open, the safety notice until it has been accepted, otherwise
//  the main app.
//

import SwiftUI

struct RootView: View {
    @Environment(PersistenceController.self) private var persistence
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        if let error = persistence.loadError {
            StoreErrorView(error: error)
        } else if !settings.hasAcceptedDisclaimer {
            DisclaimerView(onAccept: acceptDisclaimer)
        } else {
            MainTabView()
        }
    }

    private func acceptDisclaimer() {
        settings.acceptedDisclaimerVersion = SettingsStore.currentDisclaimerVersion
    }
}
