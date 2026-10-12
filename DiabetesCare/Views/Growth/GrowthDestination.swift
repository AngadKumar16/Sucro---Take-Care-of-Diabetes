//
//  GrowthDestination.swift
//  DiabetesCare
//
//  Screens pushed from Settings and Learn for stages and family. Register
//  once per navigation stack with `growthDestinations()`.
//

import SwiftUI

enum GrowthDestination: Hashable {
    case path
    case family
    /// Someone this phone follows, by id.
    case person(String)
}

extension View {
    func growthDestinations() -> some View {
        navigationDestination(for: GrowthDestination.self) { destination in
            switch destination {
            case .path: SkillPathView()
            case .family: FamilySettingsView()
            case .person(let id): FollowedPersonDestination(personID: id)
            }
        }
    }
}

/// Looks the person up when pushed, so the link only carries an id.
private struct FollowedPersonDestination: View {
    let personID: String
    @Environment(FamilyService.self) private var family

    var body: some View {
        if let person = family.followed.first(where: { $0.id == personID }) {
            CaregiverView(person: person, store: family.store(for: personID))
        } else {
            ContentUnavailableView("No Longer Followed", systemImage: "person.slash")
        }
    }
}
