//
//  FamilyRecordCodecTests.swift
//  DiabetesCare Tests
//
//  The CloudKit record layout, tested without iCloud: change sets survive
//  a trip through CKRecords, requests are batched, and bad records are
//  skipped instead of breaking a parent's refresh.
//

import Testing
import Foundation
import CloudKit
@testable import DiabetesCare

private let t0 = Date(timeIntervalSince1970: 1_800_000_000)
private let zone = CKRecordZone.ID(zoneName: FamilyCloud.zoneName, ownerName: CKCurrentUserDefaultName)

@Suite("Family record codec")
struct FamilyRecordCodecTests {
    private func sample() -> FamilyChangeSet {
        var entries = BackupArchive(exportedAt: t0, appVersion: "1")
        entries.glucose = [.init(id: UUID(), timestamp: t0, value: 64, unit: "mg/dL", trend: "falling", source: "health")]
        entries.carbs = [.init(id: UUID(), timestamp: t0, grams: 15, mealType: "snack", foodItems: "Juice")]
        entries.insulin = [.init(id: UUID(), timestamp: t0, units: 2.5, type: "bolus", deliveryMethod: "pen")]
        entries.activity = [.init(id: UUID(), timestamp: t0, type: "Soccer", duration: 60, intensity: "high", caloriesBurned: 300)]
        entries.sites = [.init(id: UUID(), timestamp: t0, location: "thigh_left", siteType: "Infusion")]
        let profile = FamilyProfile(name: "Maya", stage: .teen, urgentLow: 55, targetLow: 70, targetHigh: 180, urgentHigh: 250,
                                    glucoseUnit: "mg/dL", completedSkills: [.ranges, .units], updatedAt: t0)
        return FamilyChangeSet(profile: profile, entries: entries, deletedIDs: [UUID()],
                               helpRequests: [FamilyHelpRequest(id: UUID(), sentAt: t0, mgdl: 64)])
    }

    @Test func roundTripsEveryKind() throws {
        let changes = sample()
        let (records, deletions) = try FamilyRecordCodec.records(for: changes, zoneID: zone)
        #expect(records.count == 7)
        #expect(deletions.count == 1)
        #expect(records.allSatisfy { $0.recordID.zoneID == zone })
        #expect(records.first { $0.recordType == FamilyCloud.RecordType.profile }?.recordID.recordName == FamilyCloud.profileRecordName)

        let decoded = FamilyRecordCodec.changeSet(from: records, deleted: deletions)
        #expect(decoded.profile == changes.profile)
        #expect(decoded.entries.glucose == changes.entries.glucose)
        #expect(decoded.entries.carbs == changes.entries.carbs)
        #expect(decoded.entries.insulin == changes.entries.insulin)
        #expect(decoded.entries.activity == changes.entries.activity)
        #expect(decoded.entries.sites == changes.entries.sites)
        #expect(decoded.helpRequests == changes.helpRequests)
        #expect(decoded.deletedIDs == changes.deletedIDs)
    }

    @Test func entryRecordsAreNamedByEntryID() throws {
        let changes = sample()
        let (records, _) = try FamilyRecordCodec.records(for: changes, zoneID: zone)
        let glucose = try #require(records.first { $0["kind"] as? String == "glucose" })
        #expect(glucose.recordID.recordName == changes.entries.glucose[0].id.uuidString)
        #expect(glucose["timestamp"] as? Date == t0)
    }

    @Test func batchesStayUnderTheLimit() {
        let saves = (0..<800).map { _ in CKRecord(recordType: "Entry", recordID: CKRecord.ID(recordName: UUID().uuidString, zoneID: zone)) }
        let deletes = (0..<100).map { _ in CKRecord.ID(recordName: UUID().uuidString, zoneID: zone) }
        let batches = FamilyRecordCodec.batches(save: saves, delete: deletes)
        #expect(batches.count == 3)
        #expect(batches.allSatisfy { $0.save.count + $0.delete.count <= FamilyRecordCodec.batchSize })
        #expect(batches.map(\.save.count).reduce(0, +) == 800)
        #expect(batches.map(\.delete.count).reduce(0, +) == 100)
        #expect(FamilyRecordCodec.batches(save: [], delete: []).isEmpty)
    }

    @Test func badRecordsAreSkipped() throws {
        let (good, _) = try FamilyRecordCodec.records(for: sample(), zoneID: zone)
        let unknownKind = CKRecord(recordType: FamilyCloud.RecordType.entry, recordID: CKRecord.ID(recordName: UUID().uuidString, zoneID: zone))
        unknownKind["kind"] = "bloodPressure" as CKRecordValue
        unknownKind.encryptedValues["payload"] = Data("{}".utf8)
        let corrupt = CKRecord(recordType: FamilyCloud.RecordType.entry, recordID: CKRecord.ID(recordName: UUID().uuidString, zoneID: zone))
        corrupt["kind"] = "glucose" as CKRecordValue
        corrupt.encryptedValues["payload"] = Data("not json".utf8)
        let noPayload = CKRecord(recordType: FamilyCloud.RecordType.help, recordID: CKRecord.ID(recordName: UUID().uuidString, zoneID: zone))

        let decoded = FamilyRecordCodec.changeSet(from: good + [unknownKind, corrupt, noPayload],
                                                  deleted: [CKRecord.ID(recordName: "not-a-uuid", zoneID: zone)])
        #expect(decoded.entries.glucose.count == 1)
        #expect(decoded.helpRequests.count == 1)
        #expect(decoded.deletedIDs.isEmpty)
    }
}
