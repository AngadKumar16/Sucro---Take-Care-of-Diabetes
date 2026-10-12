//
//  SetupView.swift
//  DiabetesCare
//
//  Shown once, after the safety notice: who is this phone for? Kids and
//  teens get a grown-up passcode; a parent can set the phone up to follow
//  someone instead.
//

import SwiftUI

struct SetupView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(ParentLock.self) private var lock
    /// Called after a choice is saved, when shown from Settings.
    var onDone: () -> Void = {}
    @State private var name = ""
    @State private var pendingStage: CareStage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Who's Using DiabetesCare?")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Theme.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("The app grows with you. Start where you are now. You can move up as you learn.")
                        .foregroundStyle(Theme.soft)
                }

                TextField("First name (optional)", text: $name)
                    .textContentType(.givenName)
                    .textInputAutocapitalization(.words)
                    .padding(14)
                    .background(Theme.card, in: .rect(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.rule, lineWidth: 1))

                ForEach(CareStage.allCases, id: \.self) { stage in
                    Button { choose(stage) } label: {
                        SetupOption(symbol: stage.symbol, title: title(for: stage), detail: stage.summary, tint: tint(for: stage))
                    }
                    .buttonStyle(SetupOptionButtonStyle())
                    .accessibilityIdentifier("setup.\(stage.rawValue)")
                }

                Text("Helping someone else?")
                    .friendlyLabel()
                    .padding(.top, 4)
                Button(action: chooseCaregiver) {
                    SetupOption(symbol: "heart.circle.fill",
                                title: String(localized: "I'm a Parent or Caregiver"),
                                detail: String(localized: "Follow someone's readings from your phone and get alerts when they need help."),
                                tint: Theme.indigo)
                }
                .buttonStyle(SetupOptionButtonStyle())
                .accessibilityIdentifier("setup.caregiver")
            }
            .padding(24)
            .frame(maxWidth: 600, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .fontDesign(.rounded)
        .instrumentBackground()
        .onAppear { name = settings.userName }
        .sheet(item: $pendingStage) { stage in
            PasscodeView(mode: .create) { finish(stage) }
        }
    }

    private func title(for stage: CareStage) -> String {
        switch stage {
        case .kid: String(localized: "A Kid, with a Grown-Up in Charge")
        case .teen: String(localized: "A Teen Taking Over")
        case .adult: String(localized: "An Adult")
        }
    }

    private func tint(for stage: CareStage) -> Color {
        switch stage {
        case .kid: Theme.amber
        case .teen: Theme.green
        case .adult: Theme.ink
        }
    }

    private func choose(_ stage: CareStage) {
        if stage.hasParentLock && !lock.hasPasscode {
            pendingStage = stage
        } else {
            finish(stage)
        }
    }

    private func finish(_ stage: CareStage) {
        saveName()
        settings.appRole = .selfCare
        withAnimation(.smooth) { settings.careStage = stage }
        onDone()
    }

    private func chooseCaregiver() {
        saveName()
        withAnimation(.smooth) { settings.appRole = .caregiver }
        onDone()
    }

    private func saveName() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { settings.userName = trimmed }
    }
}

extension CareStage: Identifiable {
    var id: String { rawValue }
}

/// One choice on the setup screen: a big soft card with an icon.
struct SetupOption: View {
    let symbol: String
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 52, height: 52)
                .background(tint.opacity(0.12), in: .rect(cornerRadius: 14, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Theme.soft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.soft)
                .padding(.top, 4)
                .accessibilityHidden(true)
        }
        .softPanel()
        .accessibilityElement(children: .combine)
    }
}

struct SetupOptionButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
            .contentShape(.rect)
    }
}

#Preview {
    SetupView()
        .environment(SettingsStore(defaults: UserDefaults(suiteName: "preview")!))
        .environment(ParentLock(storage: MemoryParentLockStorage()))
}
