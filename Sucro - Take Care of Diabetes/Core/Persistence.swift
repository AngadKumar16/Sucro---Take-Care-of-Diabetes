//
//  Persistence.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import CoreData
import Observation

/// Owns the Core Data stack. If the store can't be opened (disk full, a
/// failed migration, a damaged file) the app stays up: `loadError` is set
/// and the root view shows `StoreErrorView`, which can retry or reset.
@MainActor
@Observable
final class PersistenceController {
    static let shared = PersistenceController()

    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Sample glucose readings, one an hour.
        for i in 0..<10 {
            let reading = GlucoseReading(context: viewContext)
            reading.id = UUID()
            reading.timestamp = Date().addingTimeInterval(Double(-i * 3600))
            reading.value = Double.random(in: 70...180)
            reading.unit = "mg/dL"
            reading.context = i % 2 == 0 ? "pre_meal" : "post_meal"
            reading.notes = "Sample reading \(i)"
        }

        let carbEntry = CarbEntry(context: viewContext)
        carbEntry.id = UUID()
        carbEntry.timestamp = Date()
        carbEntry.grams = 45.0
        carbEntry.mealType = "lunch"
        carbEntry.foodItems = "Rice, Chicken, Vegetables"
        carbEntry.notes = "Sample meal"

        let insulinEntry = InsulinEntry(context: viewContext)
        insulinEntry.id = UUID()
        insulinEntry.timestamp = Date()
        insulinEntry.units = 5.0
        insulinEntry.type = InsulinType.bolus.rawValue
        insulinEntry.deliveryMethod = "pen"
        insulinEntry.notes = "Sample dose"

        let activityEntry = ActivityEntry(context: viewContext)
        activityEntry.id = UUID()
        activityEntry.timestamp = Date()
        activityEntry.type = "Walking"
        activityEntry.duration = 30
        activityEntry.intensity = "moderate"
        activityEntry.caloriesBurned = 150.0
        activityEntry.notes = "Sample activity"

        try? viewContext.save()
        return result
    }()

    let container: NSPersistentContainer

    /// Set when the store failed to load. Nothing can be read or saved until
    /// `retry()` or `resetStore()` succeeds.
    private(set) var loadError: Error?

    /// - Parameters:
    ///   - inMemory: Keep data in memory only (previews).
    ///   - storeURL: Use a specific SQLite file instead of the default (tests).
    init(inMemory: Bool = false, storeURL: URL? = nil) {
        container = NSPersistentContainer(name: "SucroDataModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else if let storeURL {
            container.persistentStoreDescriptions.first?.url = storeURL
        }
        loadStores()
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    /// Tries to open the store again, for problems that may be temporary
    /// (such as a full disk).
    func retry() {
        loadStores()
    }

    /// Deletes the store files and starts with an empty database. Everything
    /// stored on this device is lost.
    func resetStore() {
        let coordinator = container.persistentStoreCoordinator
        for description in container.persistentStoreDescriptions {
            guard let url = description.url else { continue }
            do {
                try coordinator.destroyPersistentStore(at: url, type: NSPersistentStore.StoreType(rawValue: description.type))
            } catch {
                // destroyPersistentStore can fail on a file it can't parse;
                // removing the files directly still clears the way.
                let fm = FileManager.default
                for suffix in ["", "-wal", "-shm"] {
                    try? fm.removeItem(at: URL(fileURLWithPath: url.path + suffix))
                }
            }
        }
        loadStores()
    }

    private func loadStores() {
        var firstError: Error?
        container.loadPersistentStores { _, error in
            if let error, firstError == nil {
                firstError = error
            }
        }
        if let firstError {
            print("Core Data store failed to load: \(firstError)")
        }
        loadError = firstError
    }
}
