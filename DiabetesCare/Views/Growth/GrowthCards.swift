//
//  GrowthCards.swift
//  DiabetesCare
//
//  Small moments on Today that make growing up visible: a toast when a
//  habit skill is earned, and a card when someone is ready to move up.
//

import SwiftUI

/// "Skill learned" toast, shown for a few seconds.
struct SkillLearnedToast: View {
    let skill: Skill

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.title2)
                .foregroundStyle(Theme.green)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Skill Learned")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.soft)
                Text(skill.title)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
            }
            Spacer(minLength: 0)
        }
        .softPanel(padding: 14, border: Theme.green)
        .accessibilityElement(children: .combine)
    }
}

/// Shown once per stage when every skill for the next stage is done.
struct ReadyToMoveUpCard: View {
    let next: CareStage
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Label("Ready for \(next.title)", systemImage: next.symbol)
                    .font(.headline)
                    .foregroundStyle(Theme.green)
                Spacer()
                Button("Not Now", action: onDismiss)
                    .font(.subheadline)
            }
            Text("You've learned the skills for the next stage. Ask a grown-up to move you up.")
                .font(.subheadline)
                .foregroundStyle(Theme.soft)
                .fixedSize(horizontal: false, vertical: true)
            NavigationLink(value: GrowthDestination.path) {
                Text("See Your Path")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.onAccent)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Theme.green, in: .rect(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("readySeePath")
        }
        .softPanel(border: Theme.green)
    }
}
