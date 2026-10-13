//
//  ParentGate.swift
//  DiabetesCare
//
//  Runs an action if the current stage allows it, or asks for the grown-up
//  passcode first. One gate lives at the root so any screen can ask.
//

import CoreData
import SwiftUI

@MainActor
@Observable
final class ParentGate {
    struct Request: Identifiable {
        let id = UUID()
        let feature: Feature
        let action: () -> Void
    }

    /// The approval the passcode sheet is showing.
    var request: Request?

    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let lock: ParentLock

    init(settings: SettingsStore? = nil, lock: ParentLock? = nil) {
        self.settings = settings ?? .shared
        self.lock = lock ?? .shared
    }

    /// Whether the feature shows at all at this stage.
    func isAvailable(_ feature: Feature) -> Bool {
        settings.access(to: feature) != .hidden
    }

    /// Whether using the feature right now would ask for the passcode.
    func needsApproval(_ feature: Feature) -> Bool {
        settings.access(to: feature) == .parent && !lock.isUnlocked()
    }

    func run(_ feature: Feature, action: @escaping () -> Void) {
        switch settings.access(to: feature) {
        case .open:
            action()
        case .hidden:
            return
        case .parent:
            if lock.isUnlocked() {
                action()
            } else {
                request = Request(feature: feature, action: action)
            }
        }
    }

    /// Editing or deleting an entry needs the same approval as logging it:
    /// a kid can't quietly change a dose a grown-up logged.
    func runEditing(_ object: NSManagedObject, action: @escaping () -> Void) {
        switch object {
        case is InsulinEntry: run(.logInsulin, action: action)
        case is SiteChange: run(.changeSite, action: action)
        default: action()
        }
    }

    func runEditing(_ event: TimelineEvent, action: @escaping () -> Void) {
        switch event.type {
        case .bolus: run(.logInsulin, action: action)
        case .siteChange: run(.changeSite, action: action)
        case .meal, .activity: action()
        }
    }

    /// Called by the passcode sheet after a correct passcode.
    func approve(_ request: Request) {
        self.request = nil
        // Let the sheet go before the action presents anything of its own.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            request.action()
        }
    }
}

extension View {
    /// Shows the passcode sheet whenever the gate asks for approval.
    func parentGateSheet(_ gate: ParentGate) -> some View {
        sheet(item: Bindable(gate).request) { request in
            PasscodeView(mode: .approve(request.feature)) {
                gate.approve(request)
            }
        }
    }

    /// A small lock badge for rows that need a grown-up.
    func parentLockBadge(_ shown: Bool) -> some View {
        overlay(alignment: .trailing) {
            if shown {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.soft)
                    .accessibilityLabel("Needs a grown-up")
            }
        }
    }
}
