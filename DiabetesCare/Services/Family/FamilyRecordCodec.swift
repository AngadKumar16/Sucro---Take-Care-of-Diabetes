//
//  FamilyRecordCodec.swift
//  DiabetesCare
//
//  Turns change sets into CloudKit records and back. No I/O, and CKRecord
//  works without the iCloud entitlement, so this is unit tested even before
//  iCloud is switched on.
//
//  Layout in the "Family" zone:
//  - `Entry`: one per shared entry, named by the entry's UUID, with `kind`
//    (glucose/carbs/insulin/activity/site), `payload` (JSON) and `timestamp`.
//  - `Profile`: one record named "profile".
//  - `Help`: one per help request, named by its UUID.
//  - `Reply`: one per grown-up's answer to a help request, written by the
//    follower into the same zone.
//

import CloudKit
import Foundation
import OSLog

nonisolated enum FamilyRecordCodec {
    /// CloudKit takes at most 400 items per request.
    static let batchSize = 350

    enum Kind: String, CaseIterable {
        case glucose, carbs, insulin, activity, site
    }

    // MARK: - Encode

    static func records(for changes: FamilyChangeSet, zoneID: CKRecordZone.ID) throws -> (save: [CKRecord], delete: [CKRecord.ID]) {
        var records: [CKRecord] = []
        if let profile = changes.profile {
            records.append(try record(type: FamilyCloud.RecordType.profile, name: FamilyCloud.profileRecordName,
                                      payload: profile, date: profile.updatedAt, zoneID: zoneID))
        }
        let e = changes.entries
        records += try e.glucose.map { try entry(.glucose, $0.id, $0, $0.timestamp, zoneID) }
        records += try e.carbs.map { try entry(.carbs, $0.id, $0, $0.timestamp, zoneID) }
        records += try e.insulin.map { try entry(.insulin, $0.id, $0, $0.timestamp, zoneID) }
        records += try e.activity.map { try entry(.activity, $0.id, $0, $0.timestamp, zoneID) }
        records += try e.sites.map { try entry(.site, $0.id, $0, $0.timestamp, zoneID) }
        records += try changes.helpRequests.map {
            try record(type: FamilyCloud.RecordType.help, name: $0.id.uuidString, payload: $0, date: $0.sentAt, zoneID: zoneID)
        }
        let deletions = changes.deletedIDs.map { CKRecord.ID(recordName: $0.uuidString, zoneID: zoneID) }
        return (records, deletions)
    }

    /// Splits saves and deletes into requests CloudKit will accept: at most
    /// `batchSize` items per request, saves and deletes together.
    static func batches(save: [CKRecord], delete: [CKRecord.ID]) -> [(save: [CKRecord], delete: [CKRecord.ID])] {
        var result: [(save: [CKRecord], delete: [CKRecord.ID])] = []
        var saves = save[...], deletes = delete[...]
        while !saves.isEmpty || !deletes.isEmpty {
            let s = Array(saves.prefix(batchSize))
            saves = saves.dropFirst(s.count)
            let d = Array(deletes.prefix(batchSize - s.count))
            deletes = deletes.dropFirst(d.count)
            result.append((s, d))
        }
        return result
    }

    private static func entry<T: Encodable>(_ kind: Kind, _ id: UUID, _ value: T, _ date: Date?, _ zoneID: CKRecordZone.ID) throws -> CKRecord {
        let record = try record(type: FamilyCloud.RecordType.entry, name: id.uuidString, payload: value, date: date, zoneID: zoneID)
        record["kind"] = kind.rawValue as CKRecordValue
        return record
    }

    private static func record<T: Encodable>(type: String, name: String, payload: T, date: Date?, zoneID: CKRecordZone.ID) throws -> CKRecord {
        let record = CKRecord(recordType: type, recordID: CKRecord.ID(recordName: name, zoneID: zoneID))
        record["payload"] = try encoder.encode(payload) as CKRecordValue
        if let date { record["timestamp"] = date as CKRecordValue }
        return record
    }

    static func record(for reply: FamilyHelpReply, zoneID: CKRecordZone.ID) throws -> CKRecord {
        try record(type: FamilyCloud.RecordType.reply, name: reply.id.uuidString, payload: reply, date: reply.sentAt, zoneID: zoneID)
    }

    /// Replies among fetched records; anything else is ignored.
    static func replies(from records: [CKRecord]) -> [FamilyHelpReply] {
        records.compactMap { record in
            guard record.recordType == FamilyCloud.RecordType.reply, let payload = record["payload"] as? Data else { return nil }
            return try? decoder.decode(FamilyHelpReply.self, from: payload)
        }
    }

    // MARK: - Decode

    /// Builds a change set from fetched records and deleted record ids.
    /// Records it can't read are skipped and logged, never fatal.
    static func changeSet(from records: [CKRecord], deleted: [CKRecord.ID]) -> FamilyChangeSet {
        var changes = FamilyChangeSet()
        for record in records {
            add(record, to: &changes)
        }
        changes.deletedIDs = deleted.compactMap { UUID(uuidString: $0.recordName) }
        return changes
    }

    private static func add(_ record: CKRecord, to changes: inout FamilyChangeSet) {
        guard let payload = record["payload"] as? Data else { return }
        do {
            switch record.recordType {
            case FamilyCloud.RecordType.profile:
                changes.profile = try decoder.decode(FamilyProfile.self, from: payload)
            case FamilyCloud.RecordType.help:
                changes.helpRequests.append(try decoder.decode(FamilyHelpRequest.self, from: payload))
            case FamilyCloud.RecordType.entry:
                switch (record["kind"] as? String).flatMap(Kind.init(rawValue:)) {
                case .glucose: changes.entries.glucose.append(try decoder.decode(BackupArchive.Glucose.self, from: payload))
                case .carbs: changes.entries.carbs.append(try decoder.decode(BackupArchive.Carb.self, from: payload))
                case .insulin: changes.entries.insulin.append(try decoder.decode(BackupArchive.Insulin.self, from: payload))
                case .activity: changes.entries.activity.append(try decoder.decode(BackupArchive.Activity.self, from: payload))
                case .site: changes.entries.sites.append(try decoder.decode(BackupArchive.Site.self, from: payload))
                case nil: break
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
