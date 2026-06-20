//
//  Sucro___Take_Care_of_DiabetesTests.swift
//  Sucro - Take Care of Diabetes Tests
//
//  Verifies the backend added for Settings, Reports, and data management,
//  including real persistence to UserDefaults and an on-disk Core Data store.
//

import Testing
import Foundation
import CoreData
@testable import Sucro___Take_Care_of_Diabetes

// MARK: - Helpers

/// Builds an NSPersistentContainer backed by a real SQLite file on disk so we
/// can prove data survives across container reloads ("phone storage").
@MainActor
private func makeDiskContainer(at url: URL) -> NSPersistentContainer {
    let container = NSPersistentContainer(name: "SucroDataModel")
    let description = NSPersistentStoreDescription(url: url)
    description.type = NSSQLiteStoreType
    container.persistentStoreDescriptions = [description]

    var loadError: Error?
    container.loadPersistentStores { _, error in loadError = error }
    #expect(loadError == nil, "Store should load without error")
    return container
}

private func tempStoreURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("SucroTest-\(UUID().uuidString).sqlite")
}

private func removeStore(at url: URL) {
    // Remove the sqlite file and its -wal / -shm siblings.
    let fm = FileManager.default
    for suffix in ["", "-wal", "-shm"] {
        try? fm.removeItem(at: URL(fileURLWithPath: url.path + suffix))
    }
}

// MARK: - SettingsStore (UserDefaults persistence)

struct SettingsStoreTests {

    @Test func valuesPersistAcrossInstances() {
        let suiteName = "SucroTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        // Write through one instance.
        let first = SettingsStore(defaults: defaults)
        first.glucoseUnit = "mmol/L"
        first.targetLow = 80
        first.targetHigh = 160
        first.notificationsEnabled = false
        first.autoSyncEnabled = false
        first.darkModeEnabled = true

        // A brand-new instance reading the same backing store should see them.
        let second = SettingsStore(defaults: defaults)
        #expect(second.glucoseUnit == "mmol/L")
        #expect(second.targetLow == 80)
        #expect(second.targetHigh == 160)
        #expect(second.notificationsEnabled == false)
        #expect(second.autoSyncEnabled == false)
        #expect(second.darkModeEnabled == true)
    }

    @Test func defaultsAreSensibleOnFirstRun() {
        let suiteName = "SucroTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        #expect(store.glucoseUnit == "mg/dL")
        #expect(store.targetLow == 70)
        #expect(store.targetHigh == 180)
        #expect(store.notificationsEnabled == true)
    }

    @Test func targetRangeStringParsing() {
        let suiteName = "SucroTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.targetRangeString = "65-150"
        #expect(store.targetLow == 65)
        #expect(store.targetHigh == 150)
        #expect(store.targetRangeString == "65-150")

        // Invalid input is ignored (low must be < high, must be two numbers).
        store.targetRangeString = "garbage"
        #expect(store.targetLow == 65)
        store.targetRangeString = "200-100"
        #expect(store.targetLow == 65)
    }

    @Test func glucoseUnitConversion() {
        let suiteName = "SucroTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.glucoseUnit = "mg/dL"
        #expect(store.displayGlucose(180) == 180)

        store.glucoseUnit = "mmol/L"
        let mmol = store.displayGlucose(180)
        #expect(abs(mmol - 9.99) < 0.05)  // 180 / 18.0182 ≈ 9.99
    }
}

// MARK: - DataService (Core Data on-disk persistence)

@MainActor
struct DataServiceTests {

    private func seedSampleData(in context: NSManagedObjectContext) {
        let glucose = GlucoseReading(context: context)
        glucose.id = UUID()
        glucose.timestamp = Date()
        glucose.value = 120

        let insulin = InsulinEntry(context: context)
        insulin.id = UUID()
        insulin.timestamp = Date()
        insulin.units = 4
        insulin.type = "bolus"

        let carb = CarbEntry(context: context)
        carb.id = UUID()
        carb.timestamp = Date()
        carb.grams = 45

        try? context.save()
    }

    @Test func dataPersistsToDiskAcrossReloads() {
        let url = tempStoreURL()
        defer { removeStore(at: url) }

        // Write with one container...
        let container1 = makeDiskContainer(at: url)
        seedSampleData(in: container1.viewContext)

        // ...read with a brand-new container pointed at the same file.
        let container2 = makeDiskContainer(at: url)
        let readings = DataService.shared.fetchRecentGlucoseReadings(context: container2.viewContext)
        #expect(readings.count == 1)
        #expect(readings.first?.value == 120)
    }

    @Test func clearAllDataWipesEverythingAndPersists() {
        let url = tempStoreURL()
        defer { removeStore(at: url) }

        let container1 = makeDiskContainer(at: url)
        seedSampleData(in: container1.viewContext)

        // Sanity: data is present.
        #expect(DataService.shared.fetchRecentGlucoseReadings(context: container1.viewContext).count == 1)

        // Clear, then confirm gone in the same context...
        let cleared = DataService.shared.clearAllData(context: container1.viewContext)
        #expect(cleared == true)
        #expect(DataService.shared.fetchRecentGlucoseReadings(context: container1.viewContext).isEmpty)

        // ...and that the deletion is durable in a fresh container.
        let container2 = makeDiskContainer(at: url)
        #expect(DataService.shared.fetchRecentGlucoseReadings(context: container2.viewContext).isEmpty)

        let range = DateInterval(start: Date().addingTimeInterval(-86400), end: Date().addingTimeInterval(86400))
        #expect(DataService.shared.fetchInsulinEntries(context: container2.viewContext, in: range).isEmpty)
        #expect(DataService.shared.fetchCarbEntries(context: container2.viewContext, in: range).isEmpty)
    }

    @Test func rangeFetchesRespectDateBounds() {
        let url = tempStoreURL()
        defer { removeStore(at: url) }

        let container = makeDiskContainer(at: url)
        let context = container.viewContext

        // One reading now, one 10 days ago.
        let recent = GlucoseReading(context: context)
        recent.id = UUID()
        recent.timestamp = Date()
        recent.value = 100

        let old = GlucoseReading(context: context)
        old.id = UUID()
        old.timestamp = Calendar.current.date(byAdding: .day, value: -10, to: Date())
        old.value = 200
        try? context.save()

        // A 7-day window should only include the recent reading.
        let window = DateInterval(start: Date().addingTimeInterval(-7 * 86400), end: Date())
        let inWindow = DataService.shared.fetchGlucoseReadings(context: context, in: window)
        #expect(inWindow.count == 1)
        #expect(inWindow.first?.value == 100)
    }
}

// MARK: - ReportsViewModel (real statistics)

@MainActor
struct ReportsViewModelTests {

    @Test func computesStatsFromStoredData() {
        let url = tempStoreURL()
        defer { removeStore(at: url) }

        let container = makeDiskContainer(at: url)
        let context = container.viewContext

        // Ensure deterministic unit/target for the assertions.
        SettingsStore.shared.glucoseUnit = "mg/dL"
        SettingsStore.shared.targetLow = 70
        SettingsStore.shared.targetHigh = 180

        // Two readings: one in range (100), one out of range (250).
        for value in [100.0, 250.0] {
            let r = GlucoseReading(context: context)
            r.id = UUID()
            r.timestamp = Date()
            r.value = value
        }
        let insulin = InsulinEntry(context: context)
        insulin.id = UUID()
        insulin.timestamp = Date()
        insulin.units = 14
        insulin.type = "bolus"
        try? context.save()

        let vm = ReportsViewModel(context: context)
        vm.period = .weekly  // triggers recalculate

        #expect(vm.hasData == true)
        #expect(vm.avgGlucose == "175")          // (100 + 250) / 2
        #expect(vm.timeInRange == "50")          // 1 of 2 readings in range
        #expect(vm.insulinPerDay == "2.0")       // 14 units / 7 days
    }

    @Test func reportsNoDataWhenEmpty() {
        let url = tempStoreURL()
        defer { removeStore(at: url) }

        let container = makeDiskContainer(at: url)
        let vm = ReportsViewModel(context: container.viewContext)
        #expect(vm.hasData == false)
        #expect(vm.avgGlucose == "--")
    }
}
