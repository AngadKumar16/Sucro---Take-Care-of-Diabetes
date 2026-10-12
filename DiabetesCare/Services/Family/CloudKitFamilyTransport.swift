//
//  CloudKitFamilyTransport.swift
//  DiabetesCare
//
//  Family sharing over the family's own iCloud accounts. Nothing passes
//  through a server of ours.
//
//  The person with diabetes keeps a "Family" zone in their private
//  database: one record per shared entry, one profile record, and help
//  requests. A zone-wide CKShare lets invited family read that zone (read
//  only). On a follower's phone the zone shows up in the shared database.
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

    func publish(_ changes: FamilyChangeSet) async throws {
        let database = container.privateCloudDatabase
        try await ensureZone()

        var records: [CKRecord] = []
        if let profile = changes.profile {
            records.append(try record(type: FamilyCloud.RecordType.profile, name: FamilyCloud.profileRecordName, payload: profile, date: profile.updatedAt))
        }
        let e = changes.entries
        records += try e.glucose.map { try entryRecord("glucose", $0.id, $0, $0.timestamp) }
        records += try e.carbs.map { try entryRecord("carbs", $0.id, $0, $0.timestamp) }
        records += try e.insulin.map { try entryRecord("insulin", $0.id, $0, $0.timestamp) }
        records += try e.activity.map { try entryRecord("activity", $0.id, $0, $0.timestamp) }
        records += try e.sites.map { try entryRecord("site", $0.id, $0, $0.timestamp) }
        records += try changes.helpRequests.map {
            try record(type: FamilyCloud.RecordType.help, name: $0.id.uuidString, payload: $0, date: $0.sentAt)
        }
        let deletions = changes.deletedIDs.map { CKRecord.ID(recordName: $0.uuidString, zoneID: zoneID) }

        // CloudKit takes at most 400 items per request.
        let batch = 350
        for start in stride(from: 0, to: max(records.count, deletions.count), by: batch) {
            let saving = Array(records.dropFirst(start).prefix(batch))
            let deleting = Array(deletions.dropFirst(start).prefix(batch))
            guard !saving.isEmpty || !deleting.isEmpty else { continue }
            let (saved, deleted) = try await database.modifyRecords(saving: saving, deleting: deleting, savePolicy: .allKeys, atomically: false)
            for case (let id, .failure(let error)) in saved {
                Log.family.error("Couldn't share \(id.recordName, privacy: .private): \(error.localizedDescription, privacy: .public)")
            }
            for case (_, .failure(let error)) in deleted where (error as? CKError)?.code != .unknownItem {
                Log.family.error("Couldn't unshare an entry: \(error.localizedDescription, privacy: .public)")
            }
        }
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

    private func entryRecord<T: Encodable>(_ kind: String, _ id: UUID, _ entry: T, _ date: Date?) throws -> CKRecord {
        let record = try record(type: FamilyCloud.RecordType.entry, name: id.uuidString, payload: entry, date: date)
        record["kind"] = kind as CKRecordValue
        return record
    }

    private func record<T: Encodable>(type: String, name: String, payload: T, date: Date?) throws -> CKRecord {
        let record = CKRecord(recordType: type, recordID: CKRecord.ID(recordName: name, zoneID: zoneID))
        record["payload"] = try Self.encoder.encode(payload) as CKRecordValue
        if let date { record["timestamp"] = date as CKRecordValue }
        return record
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
        var changes = FamilyChangeSet()

        while true {
            let result = try await database.recordZoneChanges(inZoneWith: zone, since: serverToken)
            for case (_, .success(let modification)) in result.modificationResultsByID {
                add(modification.record, to: &changes)
            }
            for deletion in result.deletions {
                if let id = UUID(uuidString: deletion.recordID.recordName) {
                    changes.deletedIDs.append(id)
                }
            }
            serverToken = result.changeToken
            if !result.moreComing { break }
        }
        let data = serverToken.flatMap { try? NSKeyedArchiver.archivedData(withRootObject: $0, requiringSecureCoding: true) }
        return (changes, data)
    }

    private func add(_ record: CKRecord, to changes: inout FamilyChangeSet) {
        guard let payload = record["payload"] as? Data else { return }
        let decoder = Self.decoder
        do {
            switch record.recordType {
            case FamilyCloud.RecordType.profile:
                changes.profile = try decoder.decode(FamilyProfile.self, from: payload)
            case FamilyCloud.RecordType.help:
                changes.helpRequests.append(try decoder.decode(FamilyHelpRequest.self, from: payload))
            case FamilyCloud.RecordType.entry:
                switch record["kind"] as? String {
                case "glucose": changes.entries.glucose.append(try decoder.decode(BackupArchive.Glucose.self, from: payload))
                case "carbs": changes.entries.carbs.append(try decoder.decode(BackupArchive.Carb.self, from: payload))
                case "insulin": changes.entries.insulin.append(try decoder.decode(BackupArchive.Insulin.self, from: payload))
                case "activity": changes.entries.activity.append(try decoder.decode(BackupArchive.Activity.self, from: payload))
                case "site": changes.entries.sites.append(try decoder.decode(BackupArchive.Site.self, from: payload))
                default: break
                }
            default:
                break
            }
        } catch {
            Log.family.error("Couldn't read a shared record: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
