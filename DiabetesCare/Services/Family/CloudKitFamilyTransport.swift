//
//  CloudKitFamilyTransport.swift
//  DiabetesCare
//
//  Family sharing over the family's own iCloud accounts. Nothing passes
//  through a server of ours.
//
//  The person with diabetes keeps a "Family" zone in their private
//  database: one record per shared entry, one profile record, and help
//  requests. A zone-wide CKShare lets invited family read that zone. The
//  share allows writing only so family can add a `Reply` to a help
//  request; the app never writes or changes entries from a follower's
//  phone. On a follower's phone the zone shows up in the shared database.
//
//  Needs the iCloud (CloudKit) and Push Notifications capabilities, which
//  need a paid Apple Developer account. Until `FamilyCloud.containerID` is
//  set, none of this runs: creating a CKContainer without the entitlement
//  crashes the app.
//

import CloudKit
import Foundation
import OSLog

nonisolated enum FamilyCloud {
    /// Set to "iCloud.com.AngadKumar16.DiabetesCare" once the iCloud
    /// capability is on (see docs/release-checklist.md). `nil` keeps family
    /// sharing over iCloud switched off.
    static let containerID: String? = nil

    static var isAvailable: Bool { containerID != nil }

    static let zoneName = "Family"
    static let subscriptionID = "family-shared-changes"

    enum RecordType {
        static let entry = "Entry"
        static let profile = "Profile"
        static let help = "Help"
        static let reply = "Reply"
    }

    static let profileRecordName = "profile"
}

actor CloudKitFamilyTransport: FamilyTransport {
    let container: CKContainer
    private let zoneID: CKRecordZone.ID

    init(containerID: String) {
        container = CKContainer(identifier: containerID)
        zoneID = CKRecordZone.ID(zoneName: FamilyCloud.zoneName, ownerName: CKCurrentUserDefaultName)
    }

    // MARK: - Publisher

    /// Sends a change set. Throws if any record failed, so the caller keeps
    /// its old fingerprints and the whole set is retried next time (saves
    /// overwrite, so resending is harmless).
    func publish(_ changes: FamilyChangeSet) async throws {
        let database = container.privateCloudDatabase
        try await ensureZone()
        let (records, deletions) = try FamilyRecordCodec.records(for: changes, zoneID: zoneID)
        var firstError: Error?
        for batch in FamilyRecordCodec.batches(save: records, delete: deletions) {
            let (saved, deleted) = try await database.modifyRecords(saving: batch.save, deleting: batch.delete, savePolicy: .allKeys, atomically: false)
            for case (let id, .failure(let error)) in saved {
                Log.family.error("Couldn't share \(id.recordName, privacy: .private): \(error.localizedDescription, privacy: .public)")
                firstError = firstError ?? error
            }
            // Deleting something already gone is fine.
            for case (_, .failure(let error)) in deleted where (error as? CKError)?.code != .unknownItem {
                Log.family.error("Couldn't unshare an entry: \(error.localizedDescription, privacy: .public)")
                firstError = firstError ?? error
            }
        }
        if let firstError { throw firstError }
    }

    /// The zone-wide share family members are invited to. Made on first use.
    func share(title: String) async throws -> CKShare {
        try await ensureZone()
        let database = container.privateCloudDatabase
        let shareID = CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zoneID)
        if let existing = try? await database.record(for: shareID) as? CKShare {
            return existing
        }
        let share = CKShare(recordZoneID: zoneID)
        share[CKShare.SystemFieldKey.title] = title as CKRecordValue
        share.publicPermission = .none
        _ = try await database.modifyRecords(saving: [share], deleting: [])
        return share
    }

    /// Stops sharing: removes the share and the zone with everything in it.
    func stopSharing() async throws {
        _ = try await container.privateCloudDatabase.modifyRecordZones(saving: [], deleting: [zoneID])
        zoneReady = false
    }

    private var zoneReady = false

    private func ensureZone() async throws {
        guard !zoneReady else { return }
        _ = try await container.privateCloudDatabase.modifyRecordZones(saving: [CKRecordZone(zoneID: zoneID)], deleting: [])
        zoneReady = true
    }

    // MARK: - Follower

    /// Accepts an invitation the system handed to the app.
    func accept(_ metadata: CKShare.Metadata) async throws {
        _ = try await container.accept(metadata)
    }

    /// Asks CloudKit to wake this phone when anything shared with it
    /// changes, so alerts reach a parent without opening the app.
    func subscribeToSharedChanges() async throws {
        let subscription = CKDatabaseSubscription(subscriptionID: FamilyCloud.subscriptionID)
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info
        _ = try await container.sharedCloudDatabase.modifySubscriptions(saving: [subscription], deleting: [])
    }

    func followedPersonIDs() async throws -> [String] {
        try await container.sharedCloudDatabase.allRecordZones()
            .filter { $0.zoneID.zoneName == FamilyCloud.zoneName }
            .map(\.zoneID.ownerName)
    }

    func fetchChanges(for personID: String, since token: Data?) async throws -> (changes: FamilyChangeSet, token: Data?) {
        let database = container.sharedCloudDatabase
        let zone = CKRecordZone.ID(zoneName: FamilyCloud.zoneName, ownerName: personID)
        var serverToken = token.flatMap { try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: $0) }
        var records: [CKRecord] = []
        var deleted: [CKRecord.ID] = []

        while true {
            let result = try await database.recordZoneChanges(inZoneWith: zone, since: serverToken)
            for case (_, .success(let modification)) in result.modificationResultsByID {
                records.append(modification.record)
            }
            deleted += result.deletions.map(\.recordID)
            serverToken = result.changeToken
            if !result.moreComing { break }
        }
        let changes = FamilyRecordCodec.changeSet(from: records, deleted: deleted)
        let data = serverToken.flatMap { try? NSKeyedArchiver.archivedData(withRootObject: $0, requiringSecureCoding: true) }
        return (changes, data)
    }

    // MARK: - Help replies

    func sendReply(_ reply: FamilyHelpReply, to personID: String) async throws {
        let zone = CKRecordZone.ID(zoneName: FamilyCloud.zoneName, ownerName: personID)
        let record = try FamilyRecordCodec.record(for: reply, zoneID: zone)
        _ = try await container.sharedCloudDatabase.modifyRecords(saving: [record], deleting: [])
    }

    func fetchReplies(since token: Data?) async throws -> (replies: [FamilyHelpReply], token: Data?) {
        try await ensureZone()
        let database = container.privateCloudDatabase
        var serverToken = token.flatMap { try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: $0) }
        var records: [CKRecord] = []
        while true {
            let result = try await database.recordZoneChanges(inZoneWith: zoneID, since: serverToken)
            for case (_, .success(let modification)) in result.modificationResultsByID {
                records.append(modification.record)
            }
            serverToken = result.changeToken
            if !result.moreComing { break }
        }
        let data = serverToken.flatMap { try? NSKeyedArchiver.archivedData(withRootObject: $0, requiringSecureCoding: true) }
        return (FamilyRecordCodec.replies(from: records), data)
    }
}
