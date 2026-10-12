//
//  FamilyHomeView.swift
//  DiabetesCare
//
//  The main screen on a parent's or caregiver's phone: everyone they
//  follow, each opening to the read-only caregiver view.
//

import SwiftUI

struct FamilyHomeView: View {
    @Environment(FamilyService.self) private var family

    var body: some View {
        Group {
            if family.followed.count == 1, let person = family.followed.first {
                CaregiverView(person: person, store: family.store(for: person.id))
            } else if family.followed.isEmpty {
                empty
            } else {
                List(family.followed) { person in
                    NavigationLink(value: GrowthDestination.person(person.id)) {
                        FollowedPersonRow(person: person)
                    }
                    .listRowBackground(Theme.card)
                }
                .instrumentBackground()
                .navigationTitle("Family")
            }
        }
        .growthDestinations()
        .refreshable { await family.refreshFollowed() }
        .task { await family.refreshFollowed() }
    }

    private var empty: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.green)
                    .accessibilityHidden(true)
                Text("Nobody to Follow Yet")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.ink)
                VStack(alignment: .leading, spacing: 12) {
                    step(1, String(localized: "On their phone, open DiabetesCare › Settings › Family."))
                    step(2, String(localized: "Tap Share with Family and send the invitation to you."))
                    step(3, String(localized: "Open the invitation on this phone. Their readings show up here, and you get alerts when they need you."))
                }
                if !family.isCloudAvailable {
                    Label("This build isn't connected to iCloud yet, so invitations can't arrive.", systemImage: "icloud.slash")
                        .font(.subheadline)
                        .foregroundStyle(Theme.soft)
                }
            }
            .softPanel(padding: 20)
            .padding()
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .fontDesign(.rounded)
        .instrumentBackground()
        .navigationTitle("Family")
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(Theme.onAccent)
                .frame(width: 28, height: 28)
                .background(Theme.green, in: .circle)
                .accessibilityHidden(true)
            Text(text)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
