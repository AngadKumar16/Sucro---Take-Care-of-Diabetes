//
//  PasscodeView.swift
//  DiabetesCare
//
//  The grown-up passcode: a friendly keypad with four dots. Creates a new
//  passcode (typed twice) or approves one action.
//

import SwiftUI

struct PasscodeView: View {
    enum Mode: Equatable {
        /// Set a new passcode, typed twice.
        case create
        /// Approve one locked action.
        case approve(Feature)
    }

    let mode: Mode
    let onSuccess: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(ParentLock.self) private var lock
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var code = ""
    @State private var firstEntry: String?
    @State private var message: String?
    @State private var shakes = 0
    @State private var successes = 0
    /// Keys grow with Dynamic Type, up to a size three still fit across.
    @ScaledMetric(relativeTo: .title) private var scaledKey: CGFloat = 72
    private var keySize: CGFloat { min(scaledKey, 104) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    dots
                        .modifier(Shake(animatableData: CGFloat(shakes)))
                    Text(message ?? " ")
                        .font(.subheadline)
                        .foregroundStyle(Theme.vermilion)
                        .multilineTextAlignment(.center)
                        .accessibilityHidden(message == nil)
                    keypad
                }
                .padding(24)
                .frame(maxWidth: 420)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .fontDesign(.rounded)
            .instrumentBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sensoryFeedback(.error, trigger: shakes)
            .sensoryFeedback(.success, trigger: successes)
        }
        .interactiveDismissDisabled(mode == .create)
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.green)
                .accessibilityHidden(true)
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(Theme.soft)
                .multilineTextAlignment(.center)
        }
    }

    private var title: String {
        switch mode {
        case .create: firstEntry == nil ? String(localized: "Grown-Up Passcode") : String(localized: "Type It Again")
        case .approve: String(localized: "Ask a Grown-Up")
        }
    }

    private var subtitle: String {
        switch mode {
        case .create:
            String(localized: "A parent or caregiver picks 4 numbers. They're needed to change ranges, delete data or move to the next stage.")
        case .approve(let feature):
            String(localized: "\(feature.approvalReason) needs the grown-up passcode.")
        }
    }

    private var dots: some View {
        HStack(spacing: 18) {
            ForEach(0..<ParentLock.codeLength, id: \.self) { index in
                Circle()
                    .fill(index < code.count ? Theme.green : Color.clear)
                    .overlay(Circle().strokeBorder(Theme.green, lineWidth: 2))
                    .frame(width: 18, height: 18)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(code.count) of \(ParentLock.codeLength) numbers entered")
    }

    private var keypad: some View {
        let rows = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["", "0", "⌫"]]
        return Grid(horizontalSpacing: 16, verticalSpacing: 12) {
            ForEach(rows, id: \.self) { row in
                GridRow {
                    ForEach(row, id: \.self) { key in
                        keyButton(key)
                    }
                }
            }
        }
        .disabled(lock.isLockedOut())
    }

    @ViewBuilder
    private func keyButton(_ key: String) -> some View {
        if key.isEmpty {
            Color.clear.frame(width: keySize, height: keySize)
        } else if key == "⌫" {
            Button {
                if !code.isEmpty { code.removeLast() }
            } label: {
                Image(systemName: "delete.left")
                    .font(.title2)
                    .frame(width: keySize, height: keySize)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.ink)
            .accessibilityLabel("Delete")
        } else {
            Button {
                type(key)
            } label: {
                Text(key)
                    .font(.title.weight(.semibold))
                    .minimumScaleFactor(0.6)
                    .frame(width: keySize, height: keySize)
                    .background(Theme.card, in: .circle)
                    .overlay(Circle().strokeBorder(Theme.rule, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.ink)
        }
    }

    private func type(_ digit: String) {
        guard code.count < ParentLock.codeLength else { return }
        code.append(digit)
        message = nil
        if code.count == ParentLock.codeLength { finish() }
    }

    private func finish() {
        switch mode {
        case .create:
            if let first = firstEntry {
                if first == code {
                    lock.setPasscode(code)
                    successes += 1
                    onSuccess()
                    dismiss()
                } else {
                    firstEntry = nil
                    fail(String(localized: "Those didn't match. Start again."))
                }
            } else {
                firstEntry = code
                code = ""
            }
        case .approve:
            if lock.verify(code) {
                successes += 1
                onSuccess()
            } else if lock.isLockedOut() {
                fail(String(localized: "Too many tries. Wait 30 seconds."))
            } else {
                fail(String(localized: "That's not the passcode."))
            }
        }
    }

    private func fail(_ text: String) {
        message = text
        code = ""
        withAnimation(reduceMotion ? nil : .default) { shakes += 1 }
    }
}

/// Side-to-side shake for a wrong passcode.
private struct Shake: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(animatableData * .pi * 4), y: 0))
    }
}

#Preview {
    PasscodeView(mode: .create) {}
        .environment(ParentLock(storage: MemoryParentLockStorage()))
}
