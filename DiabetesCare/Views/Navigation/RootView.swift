//
//  RootView.swift
//  DiabetesCare
//
//  Decides what the app shows first: the store error screen if the database
//  couldn't open, the safety notice until it has been accepted, who the app
//  is for, then the main app (or the family view on a caregiver's phone).
//

import SwiftUI

struct RootView: View {
    @Environment(PersistenceController.self) private var persistence
    @Environment(SettingsStore.self) private var settings
    @Environment(ParentGate.self) private var gate

    var body: some View {
        Group {
            if let error = persistence.loadError {
                StoreErrorView(error: error)
            } else if !settings.hasAcceptedDisclaimer {
                DisclaimerView(onAccept: acceptDisclaimer)
            } else if !settings.hasChosenSetup {
                SetupView()
            } else if settings.appRole == .caregiver {
                CaregiverTabView()
            } else {
                MainTabView()
            }
        }
        .parentGateSheet(gate)
    }

    private func acceptDisclaimer() {
        settings.acceptedDisclaimerVersion = SettingsStore.currentDisclaimerVersion
    }
}
