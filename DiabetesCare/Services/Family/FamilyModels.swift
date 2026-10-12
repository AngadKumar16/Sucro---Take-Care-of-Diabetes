//
//  FamilyModels.swift
//  DiabetesCare
//
//  What goes from a kid's or teen's phone to a parent's. The person with
//  diabetes publishes; family members follow, read only. Entries reuse the
//  backup format, so a shared entry is exactly what a backup would hold,
//  minus photos.
//

import Foundation

/// About the person being followed: enough to label their data, color it
/// with their own ranges, and pick which alerts a parent gets.
nonisolated struct FamilyProfile: Codable, Equatable, Sendable {
    var name: String
    var stage: CareStage
    var urgentLow: Double
    var targetLow: Double
    var targetHigh: Double
    var urgentHigh: Double
    var glucoseUnit: String
    var completedSkills: [Skill]
    var updatedAt: Date

    var thresholds: GlucoseThresholds {
        GlucoseThresholds(urgentLow: urgentLow, targetLow: targetLow, targetHigh: targetHigh, urgentHigh: urgentHigh)
    }

    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? String(localized: "Family Member") : trimmed
    }
}

/// "I need help" from a kid's phone. The parent gets a notification.
nonisolated struct FamilyHelpRequest: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var sentAt: Date
    /// The latest glucose when it was sent, mg/dL.
    var mgdl: Double?
}

/// One batch of changes, from publisher to follower.
nonisolated struct FamilyChangeSet: Codable, Equatable, Sendable {
    var profile: FamilyProfile?
    /// New and edited entries. `settings` is always nil.
    var entries: BackupArchive
    var deletedIDs: [UUID] = []
    var helpRequests: [FamilyHelpRequest] = []

    init(profile: FamilyProfile? = nil, entries: BackupArchive? = nil, deletedIDs: [UUID] = [], helpRequests: [FamilyHelpRequest] = []) {
        self.profile = profile
        self.entries = entries ?? BackupArchive(exportedAt: .distantPast, appVersion: "")
        self.deletedIDs = deletedIDs
        self.helpRequests = helpRequests
    }

    var isEmpty: Bool {
        profile == nil && entries.entryCount == 0 && deletedIDs.isEmpty && helpRequests.isEmpty
    }
}

/// Someone this phone follows.
nonisolated struct FamilyPerson: Codable, Equatable, Sendable, Identifiable {
    /// Stable per person: the CloudKit zone owner, or "preview".
    var id: String
    var profile: FamilyProfile?
    var lastSync: Date?

    var displayName: String {
        profile?.displayName ?? String(localized: "Family Member")
    }
}

/// How many days of history are shared.
nonisolated enum FamilySharing {
    static let historyDays = 30
}
