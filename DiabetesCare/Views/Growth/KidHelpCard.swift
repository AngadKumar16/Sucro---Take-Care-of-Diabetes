//
//  KidHelpCard.swift
//  DiabetesCare
//
//  On a kid's Today: "Feeling off?" with two big buttons. Get Help walks
//  through finding a grown-up and treating a possible low, and can tap a
//  parent's phone when family sharing is on.
//

import SwiftUI

struct KidHelpCard: View {
    let onCheckGlucose: () -> Void
    let onHelp: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Feeling off?")
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.ink)
            Text("Shaky, sweaty, hungry, dizzy or grumpy can mean a low.")
                .font(.subheadline)
                .foregroundStyle(Theme.soft)
            HStack(spacing: 12) {
                Button(action: onCheckGlucose) {
                    Label("Check Glucose", systemImage: "drop.fill")
                }
                .buttonStyle(.soft)
                Button(action: onHelp) {
                    Label("Get Help", systemImage: "hand.raised.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.onAccent)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Theme.vermilion, in: .rect(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("kidGetHelp")
            }
        }
        .softPanel(border: Theme.amber.opacity(0.5))
    }
}

struct KidHelpView: View {
    /// The latest reading if it's recent enough to send, mg/dL.
    let latestMgdl: Double?
    let onHadCarbs: (Double) -> Void
    let onCheckGlucose: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsStore.self) private var settings
    @Environment(FamilyService.self) private var family
    @Environment(\.openURL) private var openURL
    @State private var sendState: SendState = .idle
    @State private var hadCarbs = false

    enum SendState { case idle, sending, sent, failed }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    step(1, String(localized: "Find a grown-up now."), symbol: "person.2.fill", tint: Theme.vermilion)
                    if let contact = settings.grownUpContact {
                        contactButtons(contact)
                    }
                    if settings.familySharingEnabled {
                        tellFamily
                    }
                    step(2, String(localized: "Feeling shaky or sweaty? Have 15 g of fast sugar, like a juice box or glucose tabs."), symbol: "cube.fill", tint: Theme.amber)
                    Button(hadCarbs ? "Logged 15 g" : "I Had 15 g of Sugar") {
                        onHadCarbs(15)
                        hadCarbs = true
                    }
                    .buttonStyle(.soft)
                    .disabled(hadCarbs)
                    step(3, String(localized: "Check your glucose again in 15 minutes."), symbol: "clock.fill", tint: Theme.green)
                    Button("Check Glucose Now") {
                        dismiss()
                        onCheckGlucose()
                    }
                    Text("If someone passes out or can't swallow, don't give food or drink. Call emergency services.")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.vermilion)
                        .padding(.top, 8)
                }
                .padding(20)
                .frame(maxWidth: 600, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .fontDesign(.rounded)
            .instrumentBackground()
            .navigationTitle("Get Help")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sensoryFeedback(.success, trigger: hadCarbs)
        }
    }

    @ViewBuilder
    private var tellFamily: some View {
        switch sendState {
        case .idle, .failed:
            VStack(alignment: .leading, spacing: 6) {
                Button("Tell My Grown-Up", systemImage: "bell.fill", action: send)
                    .buttonStyle(.soft)
                if sendState == .failed {
                    Text("Couldn't send. Go find them, or call.")
                        .font(.footnote)
                        .foregroundStyle(Theme.vermilion)
                }
            }
        case .sending:
            ProgressView("Sending…")
        case .sent:
            VStack(alignment: .leading, spacing: 8) {
                Label("Sent! Your grown-up's phone will buzz.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Theme.green)
                    .font(.headline)
                if let reply = family.latestReply, reply.requestID == family.lastHelpRequestID {
                    Label("\(reply.from): \(reply.message.text)", systemImage: reply.message.symbol)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                        .padding(12)
                        .background(Theme.green.opacity(0.15), in: .rect(cornerRadius: 14))
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityIdentifier("helpReply")
                } else {
                    Label("Waiting for a reply…", systemImage: "ellipsis.bubble")
                        .font(.subheadline)
                        .foregroundStyle(Theme.soft)
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                }
            }
            // Checks for the grown-up's answer while this screen is open.
            .task {
                for _ in 0..<60 {
                    if await family.checkReplies() != nil { break }
                    try? await Task.sleep(for: .seconds(10))
                    if Task.isCancelled { break }
                }
            }
            .animation(.bouncy, value: family.latestReply)
            .sensoryFeedback(.success, trigger: family.latestReply)
        }
    }

    private func contactButtons(_ contact: GrownUpContact) -> some View {
        let message = GrownUpContact.helpMessage(glucose: latestMgdl.map(settings.formattedGlucose))
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { callButton(contact); textButton(contact, message: message) }
            VStack(spacing: 12) { callButton(contact); textButton(contact, message: message) }
        }
    }

    private func callButton(_ contact: GrownUpContact) -> some View {
        Button("Call \(contact.name)", systemImage: "phone.fill") {
            if let url = contact.callURL { openURL(url) }
        }
        .buttonStyle(.soft)
        .accessibilityIdentifier("kidCallGrownUp")
    }

    private func textButton(_ contact: GrownUpContact, message: String) -> some View {
        Button("Text \(contact.name)", systemImage: "message.fill") {
            if let url = contact.textURL(message: message) { openURL(url) }
        }
        .buttonStyle(.soft)
        .accessibilityIdentifier("kidTextGrownUp")
    }

    private func send() {
        sendState = .sending
        Task {
            sendState = await family.sendHelpRequest(mgdl: latestMgdl) ? .sent : .failed
        }
    }

    private func step(_ number: Int, _ text: String, symbol: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 48, height: 48)
                .background(tint.opacity(0.12), in: .circle)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Step \(number)").friendlyLabel()
                Text(text)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
