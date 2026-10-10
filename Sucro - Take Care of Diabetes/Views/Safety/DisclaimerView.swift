//
//  DisclaimerView.swift
//  Sucro - Take Care of Diabetes
//
//  The first thing a new user sees: a printed title plate with a glucose
//  ring drawing itself in, then the safety notice as numbered clauses.
//

import SwiftUI

struct DisclaimerView: View {
    let onAccept: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawn = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                plate
                VStack(alignment: .leading, spacing: 8) {
                    Text("Before You Start")
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Five things to know about what this app can and can't do.")
                        .font(.body)
                        .foregroundStyle(Theme.soft)
                }
                SafetyNoticeContent(staggered: true)
                Text("You can read this again any time in Help.")
                    .font(.footnote)
                    .foregroundStyle(Theme.soft)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: 600, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .instrumentBackground()
        .safeAreaInset(edge: .bottom) {
            Button("I Understand", action: onAccept)
                .buttonStyle(.printPrimary)
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
                .background {
                    Theme.paper
                        .overlay(alignment: .top) { Theme.ink.frame(height: 1.5) }
                        .ignoresSafeArea()
                }
        }
        .onAppear {
            if reduceMotion {
                drawn = true
            } else {
                withAnimation(.easeInOut(duration: 1.4)) { drawn = true }
            }
        }
    }

    /// The title plate: app name and figure number above, the molecule on
    /// card stock, caption below.
    private var plate: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("DiabetesCare")
                Spacer()
                Text("Plate I")
            }
            .instrumentLabel()

            GlucoseMolecule(progress: drawn ? 1 : 0)
                .frame(maxWidth: 260)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .instrumentPanel(padding: 16)

            HStack(alignment: .firstTextBaseline) {
                Text("C₆H₁₂O₆ (Glucose): The sugar this app helps you keep in range.")
                    .foregroundStyle(Theme.soft)
            }
            .font(Theme.mono(.caption))
        }
    }
}

#Preview("Disclaimer") {
    DisclaimerView {}
}
