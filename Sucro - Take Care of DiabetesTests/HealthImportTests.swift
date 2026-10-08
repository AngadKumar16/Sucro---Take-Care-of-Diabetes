//
//  HealthImportTests.swift
//  Sucro - Take Care of Diabetes Tests
//
//  Covers the Apple Health glucose import without HealthKit: picking new
//  samples, trend arrows across a batch, and writing to Core Data.
//

import Testing
import Foundation
import CoreData
@testable import Sucro___Take_Care_of_Diabetes

private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

private func sample(_ minutesAfter: Double, _ mgdl: Double, id: UUID = UUID(), source: String = "Dexcom G7") -> HealthGlucoseImport.Sample {
    HealthGlucoseImport.Sample(uuid: id, date: t0.addingTimeInterval(minutesAfter * 60), mgdl: mgdl, sourceName: source)
}

private func glucose(_ s: HealthGlucoseImport.Sample) -> GlucoseSample {
    GlucoseSample(date: s.date, mgdl: s.mgdl)
}

@Suite("Health import logic")
struct HealthImportLogicTests {
    @Test func newSamplesSkipStoredAndRepeatedIDsAndSortOldestFirst() {
        let stored = UUID()
        let repeated = UUID()
        let incoming = [
            sample(10, 130, id: repeated),
            sample(0, 120, id: stored),
            sample(5, 125, id: repeated),
            sample(-5, 115),
        ]
        let new = HealthGlucoseImport.newSamples(incoming, existingIDs: [stored])
        #expect(new.map(\.mgdl) == [115, 125])
        #expect(new.map(\.date) == new.map(\.date).sorted())
    }

    @Test func trendsFollowTheTraceAcrossABatch() {
        // Rising 2.4 mg/dL/min every 5 minutes.
        let rising = (0..<5).map { sample(Double($0) * 5, 100 + Double($0) * 12) }
        let trends = HealthGlucoseImport.trends(for: rising.map(glucose), earlier: [])
        #expect(trends.first == .some(nil))   // nothing before it
        #expect(trends.last == .risingFast)
    }

    @Test func trendsUseStoredReadingsBeforeTheBatch() {
        let earlier = [GlucoseSample(date: t0.addingTimeInterval(-10 * 60), mgdl: 160)]
        let trends = HealthGlucoseImport.trends(for: [glucose(sample(0, 145))], earlier: earlier)
        #expect(trends == [.falling])
    }

    @Test func noTrendAcrossAGap() {
        let batch = [sample(0, 100), sample(30, 160)].map(glucose)
        #expect(HealthGlucoseImport.trends(for: batch, earlier: []) == [nil, nil])
    }

    @Test func sourceDefaultsToManual() {
        #expect(GlucoseSource(stored: nil) == .manual)
        #expect(GlucoseSource(stored: "something old") == .manual)
        #expect(GlucoseSource(stored: "health") == .health)
    }

    @Test func statusReflectsReadingAge() {
        #expect(HealthGlucoseStatus(latest: nil, now: t0) == .waiting)
        #expect(HealthGlucoseStatus(latest: t0.addingTimeInterval(-4 * 60), now: t0).isReceiving)
        #expect(HealthGlucoseStatus(latest: t0.addingTimeInterval(-40 * 60), now: t0) == .stale(age: 40 * 60))
        #expect(HealthGlucoseStatus(latest: t0, now: t0).detail == "Just now")
    }
}

@Suite("Health import store", .serialized)
@MainActor
struct HealthImportStoreTests {
    private func makeContainer() -> (NSPersistentContainer, () -> Void) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("SucroHealthTest-\(UUID().uuidString).sqlite")
        let persistence = PersistenceController(storeURL: url)
        return (persistence.container, {
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + suffix))
            }
        })
    }

    private func readings(_ context: NSManagedObjectContext) -> [GlucoseReading] {
        let request = GlucoseReading.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReading.timestamp, ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    @Test func importsOnceAndMarksSourceAndTrend() throws {
        let (container, cleanup) = makeContainer()
        defer { cleanup() }
        let context = container.newBackgroundContext()
        let batch = (0..<4).map { sample(Double($0) * 5, 100 + Double($0) * 12) }

        let first = try context.performAndWait {
            try HealthGlucoseStore.apply(added: batch, deleted: [], in: context)
        }
        #expect(first.inserted.count == 4)
        #expect(first.newestSourceName == "Dexcom G7")

        // The same samples delivered again are ignored.
        let again = try context.performAndWait {
            try HealthGlucoseStore.apply(added: batch, deleted: [], in: context)
        }
        #expect(again.inserted.isEmpty)

        let stored = readings(container.viewContext)
        #expect(stored.count == 4)
        let allFromHealth = stored.allSatisfy(\.isFromHealth)
        let allMgdl = stored.allSatisfy { $0.unit == "mg/dL" }
        #expect(allFromHealth)
        #expect(allMgdl)
        #expect(Set(stored.compactMap(\.id)) == Set(batch.map(\.uuid)))
        #expect(stored.last?.trend == GlucoseTrend.risingFast.rawValue)
    }

    @Test func deletionOnlyRemovesHealthReadings() throws {
        let (container, cleanup) = makeContainer()
        defer { cleanup() }
        let viewContext = container.viewContext

        // A manual reading that happens to share an id must survive.
        let sharedID = UUID()
        let manual = GlucoseReading(context: viewContext)
        manual.id = sharedID
        manual.timestamp = t0
        manual.value = 110
        try viewContext.save()

        let imported = sample(5, 140)
        let context = container.newBackgroundContext()
        try context.performAndWait {
            _ = try HealthGlucoseStore.apply(added: [imported], deleted: [], in: context)
        }
        let result = try context.performAndWait {
            try HealthGlucoseStore.apply(added: [], deleted: [imported.uuid, sharedID], in: context)
        }
        #expect(result.deleted.count == 1)

        viewContext.reset()
        let left = readings(viewContext)
        #expect(left.count == 1)
        #expect(left.first?.id == sharedID)
        #expect(left.first?.isFromHealth == false)
    }
}
