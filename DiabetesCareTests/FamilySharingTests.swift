//
//  FamilySharingTests.swift
//  DiabetesCare Tests
//
//  Family sharing end to end on one device: publish from a "kid" store
//  through the loopback transport into a separate "parent" store, then
//  edit and delete and check only the changes travel. Plus which alerts a
//  parent gets at each stage.
//

import Testing
import Foundation
import CoreData
@testable import DiabetesCare

private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

private func tempURL(_ suffix: String) -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("DiabetesCareFamilyTest-\(UUID().uuidString)\(suffix)")
}

private func removeStore(at url: URL) {
    for suffix in ["", "-wal", "-shm"] {
        try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + suffix))
    }
}

private func profile(_ stage: CareStage) -> FamilyProfile {
    let t = GlucoseThresholds.standard
    return FamilyProfile(name: "Maya", stage: stage, urgentLow: t.urgentLow, targetLow: t.targetLow, targetHigh: t.targetHigh,
                         urgentHigh: t.urgentHigh, glucoseUnit: "mg/dL", completedSkills: [.ranges], updatedAt: t0)
}

@MainActor
private func addReading(_ mgdl: Double, at date: Date, notes: String? = nil, in context: NSManagedObjectContext) throws -> UUID {
    let reading = GlucoseReading(context: context)
    let id = UUID()
    reading.id = id
    reading.timestamp = date
    reading.value = mgdl
    reading.unit = "mg/dL"
    reading.notes = notes
    try context.save()
    return id
}

@MainActor
private func readings(in context: NSManagedObjectContext) throws -> [GlucoseReading] {
    context.reset()
    let request: NSFetchRequest<GlucoseReading> = GlucoseReading.fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReading.timestamp, ascending: true)]
    return try context.fetch(request)
}

@MainActor
@Suite("Family sharing", .serialized)
struct FamilySharingTests {
    @Test func publishFetchApplyRoundTrip() async throws {
        let kidURL = tempURL(".sqlite"), parentURL = tempURL(".sqlite"), prints = tempURL(".json")
        defer { removeStore(at: kidURL); removeStore(at: parentURL); try? FileManager.default.removeItem(at: prints) }
        let kid = PersistenceController(storeURL: kidURL)
        let parent = PersistenceController(storeURL: parentURL)
        let transport = LoopbackFamilyTransport()
        let now = Date()

        // First publish sends everything, with the profile.
        let first = try addReading(120, at: now.addingTimeInterval(-600), in: kid.container.viewContext)
        let second = try addReading(64, at: now.addingTimeInterval(-300), in: kid.container.viewContext)
        try await FamilyService.publish(from: kid.container, profile: profile(.kid), previousProfile: nil, fingerprintsURL: prints, to: transport, now: now)
        var (changes, token) = try await transport.fetchChanges(for: LoopbackFamilyTransport.personID, since: nil)
        #expect(changes.profile?.name == "Maya")
        #expect(changes.entries.glucose.count == 2)
        try await FamilyService.apply(changes, to: parent.container)
        #expect(try readings(in: parent.container.viewContext).map(\.value) == [120, 64])

        // Nothing changed: nothing is sent.
        try await FamilyService.publish(from: kid.container, profile: profile(.kid), previousProfile: profile(.kid), fingerprintsURL: prints, to: transport, now: now)
        (changes, token) = try await transport.fetchChanges(for: LoopbackFamilyTransport.personID, since: token)
        #expect(changes.isEmpty)

        // Edit one, delete the other: only those travel.
        let context = kid.container.viewContext
        let all = try readings(in: context)
        all.first { $0.id == first }?.value = 130
        if let doomed = all.first(where: { $0.id == second }) { context.delete(doomed) }
        try context.save()
        try await FamilyService.publish(from: kid.container, profile: profile(.kid), previousProfile: profile(.kid), fingerprintsURL: prints, to: transport, now: now)
        (changes, token) = try await transport.fetchChanges(for: LoopbackFamilyTransport.personID, since: token)
        #expect(changes.profile == nil)
        #expect(changes.entries.glucose.map(\.id) == [first])
        #expect(changes.deletedIDs == [second])
        try await FamilyService.apply(changes, to: parent.container)
        let followed = try readings(in: parent.container.viewContext)
        #expect(followed.count == 1)
        #expect(followed.first?.id == first)
        #expect(followed.first?.value == 130)
    }

    @Test func oldEntriesAndPhotosStayHome() async throws {
        let url = tempURL(".sqlite")
        defer { removeStore(at: url) }
        let store = PersistenceController(storeURL: url)
        let context = store.container.viewContext
        let now = Date()
        _ = try addReading(100, at: now.addingTimeInterval(-40 * 86_400), in: context)
        _ = try addReading(110, at: now.addingTimeInterval(-3600), notes: "felt fine", in: context)
        let site = SiteChange(context: context)
        site.id = UUID()
        site.timestamp = now
        site.location = SiteLocation.thighLeft.rawValue
        site.photo = Data([1, 2, 3])
        site.notes = "itchy"
        try context.save()

        let teen = try FamilyStore.shareableArchive(in: context, stage: .teen, now: now)
        #expect(teen.glucose.map(\.value) == [110])
        #expect(teen.glucose.first?.notes == nil)
        #expect(teen.sites.first?.photo == nil)
        #expect(teen.sites.first?.notes == nil)

        // A kid's notes go to the parent; photos never do.
        let kid = try FamilyStore.shareableArchive(in: context, stage: .kid, now: now)
        #expect(kid.glucose.first?.notes == "felt fine")
        #expect(kid.sites.first?.photo == nil)
    }

    @Test func diffFindsNewChangedAndRemoved() {
        var archive = BackupArchive(exportedAt: t0, appVersion: "1")
        let a = UUID(), b = UUID()
        archive.glucose = [.init(id: a, timestamp: t0, value: 100), .init(id: b, timestamp: t0, value: 140)]
        let first = FamilyDiff.changes(from: [:], to: archive)
        #expect(first.entries.glucose.count == 2)
        #expect(first.deleted.isEmpty)

        var next = archive
        next.glucose = [.init(id: a, timestamp: t0, value: 101)]
        let second = FamilyDiff.changes(from: first.fingerprints, to: next)
        #expect(second.entries.glucose.map(\.id) == [a])
        #expect(second.deleted == [b])
    }
}

@Suite("Caregiver alerts")
struct CaregiverAlertTests {
    let policy = CaregiverAlertPolicy()

    private func evaluate(_ mgdl: Double, stage: CareStage, state: CaregiverAlertState = CaregiverAlertState()) -> [CaregiverAlert] {
        policy.evaluate(samples: [GlucoseSample(date: t0, mgdl: mgdl)], profile: profile(stage), helpRequests: [], state: state, now: t0).alerts
    }

    @Test func kidParentHearsEveryLowAndHigh() {
        #expect(evaluate(65, stage: .kid) == [.glucose(.low, mgdl: 65)])
        #expect(evaluate(50, stage: .kid) == [.glucose(.urgentLow, mgdl: 50)])
        #expect(evaluate(260, stage: .kid) == [.glucose(.urgentHigh, mgdl: 260)])
        #expect(evaluate(120, stage: .kid).isEmpty)
    }

    @Test func teenParentHearsOnlyUrgent() {
        #expect(evaluate(65, stage: .teen).isEmpty)
        #expect(evaluate(50, stage: .teen) == [.glucose(.urgentLow, mgdl: 50)])
        #expect(evaluate(260, stage: .teen) == [.glucose(.urgentHigh, mgdl: 260)])
    }

    @Test func adultSharesUrgentLowsOnly() {
        #expect(evaluate(260, stage: .adult).isEmpty)
        #expect(evaluate(50, stage: .adult) == [.glucose(.urgentLow, mgdl: 50)])
    }

    @Test func sameLowNotifiesOnce() {
        let first = policy.evaluate(samples: [GlucoseSample(date: t0, mgdl: 60)], profile: profile(.kid), helpRequests: [], state: CaregiverAlertState(), now: t0)
        let again = policy.evaluate(samples: [GlucoseSample(date: t0.addingTimeInterval(300), mgdl: 58)], profile: profile(.kid), helpRequests: [],
                                    state: first.state, now: t0.addingTimeInterval(300))
        #expect(first.alerts.count == 1)
        #expect(again.alerts.isEmpty)
    }

    @Test func helpRequestsNotifyOnceWhileFresh() {
        let request = FamilyHelpRequest(id: UUID(), sentAt: t0, mgdl: 70)
        let first = policy.evaluate(samples: [], profile: profile(.kid), helpRequests: [request], state: CaregiverAlertState(), now: t0.addingTimeInterval(60))
        #expect(first.alerts == [.helpRequested(request)])
        let again = policy.evaluate(samples: [], profile: profile(.kid), helpRequests: [request], state: first.state, now: t0.addingTimeInterval(120))
        #expect(again.alerts.isEmpty)
        let stale = policy.evaluate(samples: [], profile: profile(.kid), helpRequests: [request], state: CaregiverAlertState(), now: t0.addingTimeInterval(3600))
        #expect(stale.alerts.isEmpty)
    }

    @Test func missingCGMDataForKidsOnly() {
        // A CGM stream every 5 minutes, then nothing for 25 minutes.
        let samples = (0..<6).map { GlucoseSample(date: t0.addingTimeInterval(Double($0) * 300), mgdl: 120) }
        let now = t0.addingTimeInterval(25 * 60 + 25 * 60)
        let kid = policy.evaluate(samples: samples, profile: profile(.kid), helpRequests: [], state: CaregiverAlertState(), now: now)
        #expect(kid.alerts == [.noRecentData(lastReading: samples.last!.date)])
        let teen = policy.evaluate(samples: samples, profile: profile(.teen), helpRequests: [], state: CaregiverAlertState(), now: now)
        #expect(teen.alerts.isEmpty)
    }
}
