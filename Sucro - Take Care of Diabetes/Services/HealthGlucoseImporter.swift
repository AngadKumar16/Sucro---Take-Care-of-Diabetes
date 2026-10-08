//
//  HealthGlucoseImporter.swift
//  Sucro - Take Care of Diabetes
//
//  Reads blood glucose from Apple Health, which is where CGM apps such as
//  Dexcom and Libre share their readings. An observer query (with background
//  delivery) wakes the app when Health gets new samples; an anchored query
//  then fetches only what changed since the last import.
//
//  Samples this app wrote itself are excluded, so manual readings mirrored
//  to Health never come back as duplicates. Imported readings keep the
//  Health sample's UUID as their `id` and are marked `source = "health"`, so
//  re-delivered samples are skipped and deletions in Health carry over.
//
//  The import runs on a background context with batch requests, then merges
//  the changes into the view context.
//

import CoreData
import Foundation
import HealthKit
import Observation

@Observable
final class HealthGlucoseImporter {
    static let shared = HealthGlucoseImporter()

    /// When an import last changed stored readings. Views watch this to refetch.
    private(set) var lastChange: Date?
    /// When the last import finished, whether or not it found anything.
    private(set) var lastSync: Date?
    private(set) var isSyncing = false
    private(set) var lastError: String?
    /// The app that recorded the newest imported reading, such as "Dexcom G7".
    private(set) var latestSourceName: String?
    var isRunning: Bool { container != nil }

    @ObservationIgnored private var container: NSPersistentContainer?
    @ObservationIgnored private var backgroundContext: NSManagedObjectContext?
    @ObservationIgnored private var observer: HKObserverQuery?
    @ObservationIgnored private var needsAnotherPass = false
    @ObservationIgnored private let defaults: UserDefaults

    private static let anchorKey = "health.glucose.anchor"
    private static let sourceNameKey = "health.glucose.latestSource"
    nonisolated private static let glucoseType = HKQuantityType(.bloodGlucose)

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        latestSourceName = defaults.string(forKey: Self.sourceNameKey)
    }

    // MARK: - Lifecycle

    /// Starts listening for new Health glucose. Call at launch, before the
    /// first scene, so a background wake from HealthKit finds the observer
    /// registered. Does nothing if Health isn't available or it's running.
    func start(container: NSPersistentContainer) {
        guard self.container == nil, HKHealthStore.isHealthDataAvailable() else { return }
        self.container = container
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        backgroundContext = context
        registerObserver()
    }

    /// Sets the observer up again, then imports anything new. Call after the
    /// Health permission sheet and whenever the app comes to the foreground:
    /// an observer started before the user answered the permission sheet
    /// stays dead, so it's replaced rather than trusted.
    func refresh() async {
        guard isRunning else { return }
        observerFailed()
        registerObserver()
        await sync()
    }

    private func registerObserver() {
        guard observer == nil else { return }
        let store = HealthKitManager.shared.healthStore
        let query = Self.makeObserverQuery(
            onChange: { [weak self] in await self?.sync() },
            onError: { [weak self] in await self?.observerFailed() }
        )
        store.execute(query)
        observer = query

        Task {
            do {
                try await store.enableBackgroundDelivery(for: Self.glucoseType, frequency: .immediate)
            } catch {
                print("Health background delivery not enabled: \(error.localizedDescription)")
            }
        }
    }

    private func observerFailed() {
        if let observer {
            HealthKitManager.shared.healthStore.stop(observer)
        }
        observer = nil
    }

    /// Fetches whatever changed in Health since the last import. Calls made
    /// while an import is running are folded into one more pass.
    func sync() async {
        guard let backgroundContext, let container else { return }
        if isSyncing {
            needsAnotherPass = true
            return
        }
        isSyncing = true
        defer { isSyncing = false }

        repeat {
            needsAnotherPass = false
            do {
                let changes = try await Self.fetchChanges(
                    store: HealthKitManager.shared.healthStore,
                    anchor: anchor,
                    now: Date()
                )
                let result = try await Self.apply(changes, to: backgroundContext)
                anchor = changes.anchor
                lastError = nil
                lastSync = Date()

                if let name = result.newestSourceName {
                    latestSourceName = name
                    defaults.set(name, forKey: Self.sourceNameKey)
                }
                if !result.inserted.isEmpty || !result.deleted.isEmpty {
                    let viewContext = container.viewContext
                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: [NSInsertedObjectsKey: result.inserted, NSDeletedObjectsKey: result.deleted],
                        into: [viewContext]
                    )
                    AlertService.shared.evaluate(context: viewContext)
                    lastChange = Date()
                }
            } catch {
                lastError = error.localizedDescription
                print("Health glucose import failed: \(error.localizedDescription)")
                return
            }
        } while needsAnotherPass
    }

    /// Forgets how far the import got, so the next sync reads the last 30
    /// days from Health again. Used after Clear All Data.
    func resetAnchor() {
        anchor = nil
        latestSourceName = nil
        defaults.removeObject(forKey: Self.sourceNameKey)
    }

    // MARK: - Anchor

    private var anchor: HKQueryAnchor? {
        get {
            guard let data = defaults.data(forKey: Self.anchorKey) else { return nil }
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
        }
        set {
            if let newValue,
               let data = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true) {
                defaults.set(data, forKey: Self.anchorKey)
            } else {
                defaults.removeObject(forKey: Self.anchorKey)
            }
        }
    }

    // MARK: - HealthKit

    nonisolated private struct Changes {
        let added: [HealthGlucoseImport.Sample]
        let deleted: [UUID]
        let anchor: HKQueryAnchor
    }

    /// HealthKit calls the handler on its own queue, so the query is built
    /// outside the main actor.
    nonisolated private static func makeObserverQuery(
        onChange: @escaping @Sendable () async -> Void,
        onError: @escaping @Sendable () async -> Void
    ) -> HKObserverQuery {
        HKObserverQuery(sampleType: glucoseType, predicate: nil) { _, completion, error in
            guard error == nil else {
                completion()
                Task { await onError() }
                return
            }
            Task {
                await onChange()
                completion()
            }
        }
    }

    nonisolated private static func fetchChanges(store: HKHealthStore, anchor: HKQueryAnchor?, now: Date) async throws -> Changes {
        var predicate: NSPredicate = NSCompoundPredicate(
            notPredicateWithSubpredicate: HKQuery.predicateForObjects(from: .default())
        )
        if anchor == nil {
            let recent = HKQuery.predicateForSamples(withStart: now.addingTimeInterval(-HealthGlucoseImport.backfill), end: nil)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, recent])
        }
        let descriptor = HKAnchoredObjectQueryDescriptor(
            predicates: [.quantitySample(type: glucoseType, predicate: predicate)],
            anchor: anchor
        )
        let result = try await descriptor.result(for: store)
        let mgdl = HKUnit(from: "mg/dL")
        let added = result.addedSamples.map {
            HealthGlucoseImport.Sample(
                uuid: $0.uuid,
                date: $0.startDate,
                mgdl: $0.quantity.doubleValue(for: mgdl),
                sourceName: $0.sourceRevision.source.name
            )
        }
        return Changes(added: added, deleted: result.deletedObjects.map(\.uuid), anchor: result.newAnchor)
    }

    // MARK: - Core Data

    /// Writes one batch of changes. Batch requests keep the work off managed
    /// objects, which are main-actor types in this app.
    nonisolated private static func apply(_ changes: Changes, to context: NSManagedObjectContext) async throws -> HealthGlucoseStore.Result {
        try await context.perform {
            try HealthGlucoseStore.apply(added: changes.added, deleted: changes.deleted, in: context)
        }
    }
}
