//
//  CareStage.swift
//  DiabetesCare
//
//  The app grows with the person using it. A kid's phone keeps a grown-up
//  in charge, a teen does the logging with a parent watching from a
//  distance, and an adult gets everything. What each stage can do lives
//  here and nowhere else, so screens ask `access(to:)` instead of checking
//  the stage themselves.
//

import Foundation

/// Who the app is set up for on this phone.
nonisolated enum CareStage: String, Codable, CaseIterable, Sendable {
    case kid
    case teen
    case adult

    var title: String {
        switch self {
        case .kid: String(localized: "Kid")
        case .teen: String(localized: "Teen")
        case .adult: String(localized: "Adult")
        }
    }

    var symbol: String {
        switch self {
        case .kid: "figure.and.child.holdinghands"
        case .teen: "figure.walk"
        case .adult: "figure.stand"
        }
    }

    /// One line on what changes at this stage.
    var summary: String {
        switch self {
        case .kid: String(localized: "A grown-up is in charge. Big, simple buttons, and every reading goes to family.")
        case .teen: String(localized: "You log and decide. A parent can see how you're doing and gets only urgent alerts.")
        case .adult: String(localized: "Everything, your way. Share with family or your doctor if you want to.")
        }
    }

    /// The stage after this one, if there is one.
    var next: CareStage? {
        switch self {
        case .kid: .teen
        case .teen: .adult
        case .adult: nil
        }
    }

    /// Kids and teens need a grown-up's passcode for the riskier settings.
    var hasParentLock: Bool { self != .adult }

    /// Skills that show someone is ready for the next stage. A parent still
    /// approves the move.
    var skillsToMoveUp: [Skill] {
        switch self {
        case .kid: Skill.allCases.filter(\.isQuiz)
        case .teen: Skill.allCases
        case .adult: []
        }
    }

    func isReadyToMoveUp(completed: Set<Skill>) -> Bool {
        next != nil && Set(skillsToMoveUp).isSubset(of: completed)
    }

    /// Whether a feature is open, needs a grown-up's passcode, or isn't
    /// offered at all at this stage. Skills a kid has finished can open
    /// up features early.
    func access(to feature: Feature, completed: Set<Skill> = []) -> FeatureAccess {
        let base: FeatureAccess
        switch (self, feature) {
        case (.adult, _):
            base = .open
        case (.kid, .quickBolus):
            base = .hidden
        case (.kid, .logInsulin), (.kid, .changeSite), (.kid, .editInsulinSettings):
            base = .parent
        case (.teen, .logInsulin), (.teen, .changeSite), (.teen, .quickBolus), (.teen, .editInsulinSettings):
            base = .open
        case (_, .editThresholds), (_, .turnOffNotifications), (_, .clearData),
             (_, .restoreBackup), (_, .changeStage), (_, .stopSharing), (_, .editGrownUpContact):
            base = .parent
        }
        if base == .parent, let skills = Skill.unlocking(feature, at: self), Set(skills).isSubset(of: completed) {
            return .open
        }
        return base
    }
}

/// Things the app gates by stage.
nonisolated enum Feature: String, CaseIterable, Sendable {
    case logInsulin
    case quickBolus
    case changeSite
    case editThresholds
    case editInsulinSettings
    case turnOffNotifications
    case clearData
    case restoreBackup
    case changeStage
    case stopSharing
    case editGrownUpContact

    /// Shown on the passcode screen: what the grown-up is approving.
    var approvalReason: String {
        switch self {
        case .logInsulin: String(localized: "Log an insulin dose")
        case .quickBolus: String(localized: "Log a bolus")
        case .changeSite: String(localized: "Log a site change")
        case .editThresholds: String(localized: "Change glucose ranges")
        case .editInsulinSettings: String(localized: "Change insulin settings")
        case .turnOffNotifications: String(localized: "Turn off notifications")
        case .clearData: String(localized: "Delete all data")
        case .restoreBackup: String(localized: "Restore a backup")
        case .changeStage: String(localized: "Change who the app is set up for")
        case .stopSharing: String(localized: "Stop sharing with family")
        case .editGrownUpContact: String(localized: "Change who to call for help")
        }
    }
}

nonisolated enum FeatureAccess: Sendable {
    /// Anyone can use it.
    case open
    /// Works after a grown-up enters the passcode.
    case parent
    /// Not offered at this stage.
    case hidden
}

/// Whether this phone belongs to the person with diabetes, or to someone
/// who follows them.
nonisolated enum AppRole: String, Codable, Sendable {
    case selfCare
    case caregiver
}
