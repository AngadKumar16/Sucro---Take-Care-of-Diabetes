//
//  BackupTests.swift
//  Sucro - Take Care of Diabetes Tests
//
//  Covers the JSON backup: every entity survives a round trip, restoring
//  merges by id or replaces everything, and old backups are pruned.
//

import Testing
import Foundation
import CoreData
@testable import Sucro___Take_Care_of_Diabetes

private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

private func isolatedDefaults() -> (UserDefaults, () -> Void) {
    let name = "SucroBackupTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    return (defaults, { defaults.removePersistentDomain(forName: name) })
}

private func tempURL(_ suffix: String) -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("SucroBackupTest-\(UUID().uuidString)\(suffix)")
}

private func removeStore(at url: URL) {
    for suffix in ["", "-wal", "-shm"] {
        try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + suffix))
    }
}

@MainActor
private func fill(_ context: NSManagedObjectContext) throws {
    let manual = GlucoseReading(context: context)
    manual.id = UUID()
    manual.timestamp = t0
    manual.value = 142
    manual.unit = "mg/dL"
    manual.trend = GlucoseTrend.rising.rawValue
    manual.context = "post_meal"
    manual.notes = "after lunch, \"big\" one"

    let health = GlucoseReading(context: context)
    health.id = UUID()
    health.timestamp = t0.addingTimeInterval(300)
    health.value = 150
    health.unit = "mg/dL"
    health.source = GlucoseSource.health.rawValue

    let carbs = CarbEntry(context: context)
    carbs.id = UUID()
    carbs.timestamp = t0
    carbs.grams = 45
    carbs.mealType = "Lunch"
    carbs.foodItems = "Rice"

    let insulin = InsulinEntry(context: context)
    insulin.id = UUID()
    insulin.timestamp = t0
    insulin.units = 4.5
    insulin.type = InsulinType.bolus.rawValue
    insulin.deliveryMethod = "Pen"

    let activity = ActivityEntry(context: context)
    activity.id = UUID()
    activity.timestamp = t0
    activity.type = "Walking"
    activity.duration = 30
    activity.intensity = "Moderate"
    activity.caloriesBurned = 120

    let site = SiteChange(context: context)
    site.id = UUID()
    site.timestamp = t0
    site.location = SiteLocation.thighLeft.rawValue
    site.siteType = "Infusion"
    site.deviceType = "Pump"
    site.photo = Data([0xFF, 0xD8, 0x01, 0x02])

    try context.save()
}

@MainActor
private func count(_ entity: String, in context: NSManagedObjectContext) throws -> Int {
    try context.count(for: NSFetchRequest(entityName: entity))
}

@MainActor
@Suite("Backup", .serialized)
struct BackupTests {
    @Test func archiveRoundTripsThroughJSON() throws {
        let url = tempURL(".sqlite")
        defer { removeStore(at: url) }
        let store = PersistenceController(storeURL: url)
        let context = store.container.viewContext
        try fill(context)

        let archive = try BackupStore.makeArchive(in: context, settings: nil, appVersion: "1.0 (1)", now: t0)
        #expect(archive.glucose.count == 2)
        #expect(archive.entryCount == 6)
        #expect(archive.sites.first?.photo == Data([0xFF, 0xD8, 0x01, 0x02]))

        let decoded = try BackupArchive.decode(archive.encoded())
        #expect(decoded == archive)
    }

    @Test func restoreIntoEmptyStoreKeepsEveryField() throws {
        let sourceURL = tempURL(".sqlite")
        let targetURL = tempURL(".sqlite")
        defer { removeStore(at: sourceURL); removeStore(at: targetURL) }
        let source = PersistenceController(storeURL: sourceURL)
        try fill(source.container.viewContext)
        let archive = try BackupStore.makeArchive(in: source.container.viewContext, settings: nil, appVersion: "1", now: t0)

        let target = PersistenceController(storeURL: targetURL)
        let context = target.container.viewContext
        let result = try BackupStore.restore(archive, mode: .merge, in: context)
        #expect(result.added == 6)
        #expect(result.skipped == 0)

        let again = try BackupStore.makeArchive(in: context, settings: nil, appVersion: "1", now: t0)
        #expect(again == archive)
        let health = again.glucose.first { $0.source == GlucoseSource.health.rawValue }
        #expect(health != nil, "Apple Health readings keep their source")
    }

    @Test func mergeSkipsEntriesAlreadyStored() throws {
        let url = tempURL(".sqlite")
        defer { removeStore(at: url) }
        let store = PersistenceController(storeURL: url)
        let context = store.container.viewContext
        try fill(context)
        let archive = try BackupStore.makeArchive(in: context, settings: nil, appVersion: "1", now: t0)

        let extra = GlucoseReading(context: context)
        extra.id = UUID()
        extra.timestamp = t0.addingTimeInterval(600)
        extra.value = 99
        try context.save()

        let result = try BackupStore.restore(archive, mode: .merge, in: context)
        #expect(result.added == 0)
        #expect(result.skipped == 6)
        #expect(try count("GlucoseReading", in: context) == 3)
    }

    @Test func replaceDeletesEverythingFirst() throws {
        let url = tempURL(".sqlite")
        defer { removeStore(at: url) }
        let store = PersistenceController(storeURL: url)
        let context = store.container.viewContext
        try fill(context)
        let archive = try BackupStore.makeArchive(in: context, settings: nil, appVersion: "1", now: t0)

        let extra = CarbEntry(context: context)
        extra.id = UUID()
        extra.grams = 10
        try context.save()

        let result = try BackupStore.restore(archive, mode: .replace, in: context)
        #expect(result.added == 6)
        context.reset()
        #expect(try count("CarbEntry", in: context) == 1)
        #expect(try count("GlucoseReading", in: context) == 2)
    }

    @Test func newerVersionIsRejectedWithAReadableError() throws {
        var archive = BackupArchive(exportedAt: t0, appVersion: "9")
        archive.version = BackupArchive.currentVersion + 1
        #expect(throws: BackupArchive.ReadError.self) {
            try BackupArchive.decode(archive.encoded())
        }
        #expect(throws: BackupArchive.ReadError.self) {
            try BackupArchive.decode(Data("{\"hello\": 1}".utf8))
        }
    }

    @Test func settingsAreCarriedAndApplied() {
        let (defaults, cleanup) = isolatedDefaults()
        defer { cleanup() }
        let settings = SettingsStore(defaults: defaults)
        var backup = settings.backupSettings
        backup.glucoseUnit = "mmol/L"
        backup.targetHigh = 160
        backup.insulinActionHours = 10   // out of range, gets clamped
        settings.apply(backup)
        #expect(settings.glucoseUnit == "mmol/L")
        #expect(settings.targetHigh == 160)
        #expect(settings.insulinActionHours == SettingsStore.insulinActionBounds.upperBound)
    }

    @Test func dailyBackupKeepsTheNewestSeven() async throws {
        let (defaults, cleanup) = isolatedDefaults()
        defer { cleanup() }
        let storeURL = tempURL(".sqlite")
        let directory = tempURL("-backups")
        defer { removeStore(at: storeURL); try? FileManager.default.removeItem(at: directory) }
        let store = PersistenceController(storeURL: storeURL)
        try fill(store.container.viewContext)
        let service = BackupService(settings: SettingsStore(defaults: defaults), directory: directory)

        for day in 0..<9 {
            let url = await service.performBackup(container: store.container, now: t0.addingTimeInterval(Double(day) * 86_400))
            #expect(url != nil)
        }
        let files = try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted()
        #expect(files.count == BackupService.keptBackups)
        #expect(files.last == BackupService.fileName(for: t0.addingTimeInterval(8 * 86_400)))

        let newest = try BackupArchive.decode(Data(contentsOf: directory.appendingPathComponent(files.last!)))
        #expect(newest.entryCount == 6)
    }
}
