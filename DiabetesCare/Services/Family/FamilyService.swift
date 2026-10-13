//
//  FamilyService.swift
//  DiabetesCare
//
//  Runs family sharing on this phone, in either direction:
//
//  - Publisher (the person with diabetes, sharing on): after anything is
//    saved, works out what changed in the last 30 days and sends it.
//  - Follower (a parent): pulls each followed person's changes into their
//    own read-only store and raises the alerts a parent should get.
//
//  The transport is iCloud when it's set up (`FamilyCloud.isAvailable`).
//  The preview runs the same publish → fetch → apply path in memory.
//

import CloudKit
import CoreData
import Foundation
import Observation
import OSLog
import UIKit

@MainActor
@Observable
final class FamilyService {
    static let shared = FamilyService()

    // MARK: State

    /// People this phone follows, newest first.
    private(set) var followed: [FamilyPerson] = []
    private(set) var lastPublished: Date?
    private(set) var isWorking = false
    /// Shown in Family settings when something went wrong.
    var lastError: String?

    var isCloudAvailable: Bool { cloud != nil }

    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let transport: FamilyTransport?
    @ObservationIgnored private let cloud: CloudKitFamilyTransport?
    @ObservationIgnored private var container: NSPersistentContainer?
    @ObservationIgnored private var stores: [String: PersistenceController] = [:]
    @ObservationIgnored private var saveObserver: NSObjectProtocol?
    @ObservationIgnored private var publishTask: Task<Void, Never>?
    @ObservationIgnored private let policy = CaregiverAlertPolicy()

    private enum Key {
        static let followed = "family.followed"
        static let tokens = "family.tokens"
        static let lastPublished = "family.lastPublished"
        static let publishedProfile = "family.publishedProfile"
        static func alertState(_ id: String) -> String { "family.alerts.\(id)" }
    }

    /// - Parameter transport: Injected in tests. By default, iCloud when
    ///   it's set up, otherwise nothing (sharing stays off).
    init(settings: SettingsStore? = nil, defaults: UserDefaults = .standard, transport: FamilyTransport? = nil) {
        self.settings = settings ?? .shared
        self.defaults = defaults
        if let transport {
            self.transport = transport
            self.cloud = transport as? CloudKitFamilyTransport
        } else if let id = FamilyCloud.containerID {
            let cloud = CloudKitFamilyTransport(containerID: id)
            self.cloud = cloud
            self.transport = cloud
        } else {
            self.cloud = nil
            self.transport = nil
        }
        if let data = defaults.data(forKey: Key.followed),
           let people = try? JSONDecoder().decode([FamilyPerson].self, from: data) {
            followed = people
        }
        lastPublished = defaults.object(forKey: Key.lastPublished) as? Date
    }

    // MARK: - Publisher

    /// Watches the main store so changes are shared shortly after they're
    /// saved. Safe to call more than once.
    func start(container: NSPersistentContainer) {
        self.container = container
        guard saveObserver == nil else { return }
        let coordinator = container.persistentStoreCoordinator
        saveObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave, object: nil, queue: .main
        ) { [weak self] note in
            guard let context = note.object as? NSManagedObjectContext,
                  context.persistentStoreCoordinator === coordinator else { return }
            MainActor.assumeIsolated { self?.schedulePublish() }
        }
    }

    /// Publishes a few seconds from now, so a burst of saves (a CGM import)
    /// goes out as one batch.
    func schedulePublish(after delay: Duration = .seconds(3)) {
        guard settings.familySharingEnabled, transport != nil else { return }
        publishTask?.cancel()
        publishTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await self?.publishNow()
        }
    }

    func publishNow() async {
        guard settings.familySharingEnabled, let transport, let container else { return }
        do {
            try await Self.publish(from: container, profile: makeProfile(), previousProfile: publishedProfile,
                                   fingerprintsURL: Self.fingerprintsURL, to: transport)
            publishedProfile = makeProfile()
            lastPublished = Date()
            defaults.set(lastPublished, forKey: Key.lastPublished)
            lastError = nil
        } catch {
            Log.family.error("Family publish failed: \(error.localizedDescription, privacy: .public)")
            lastError = error.localizedDescription
        }
    }

    /// Works out and sends what changed. Fingerprints are only saved after
    /// a successful send, so a failure is retried next time.
    nonisolated static func publish(from container: NSPersistentContainer, profile: FamilyProfile, previousProfile: FamilyProfile?,
                                    fingerprintsURL: URL, to transport: FamilyTransport, now: Date = Date()) async throws {
        let previous = (try? Data(contentsOf: fingerprintsURL)).flatMap { try? JSONDecoder().decode(FamilyDiff.Fingerprints.self, from: $0) } ?? [:]
        let context = container.newBackgroundContext()
        let archive = try await context.perform {
            try FamilyStore.shareableArchive(in: context, stage: profile.stage, now: now)
        }
        let diff = FamilyDiff.changes(from: previous, to: archive)
        let profileChanged = previousProfile.map { !$0.sameContent(as: profile) } ?? true
        let changes = FamilyChangeSet(profile: profileChanged ? profile : nil, entries: diff.entries, deletedIDs: diff.deleted)
        guard !changes.isEmpty else { return }
        try await transport.publish(changes)
        try JSONEncoder().encode(diff.fingerprints).write(to: fingerprintsURL, options: .atomic)
    }

    func makeProfile(now: Date = Date()) -> FamilyProfile {
        FamilyProfile(
            name: settings.userName,
            stage: settings.stage,
            urgentLow: settings.urgentLow,
            targetLow: settings.targetLow,
            targetHigh: settings.targetHigh,
            urgentHigh: settings.urgentHigh,
            glucoseUnit: settings.glucoseUnit,
            completedSkills: settings.completedSkills.sorted { $0.rawValue < $1.rawValue },
            updatedAt: now
        )
    }

    /// "I need help" from a kid. Returns whether it could be sent.
    func sendHelpRequest(mgdl: Double?) async -> Bool {
        guard settings.familySharingEnabled, let transport else { return false }
        do {
            try await transport.publish(FamilyChangeSet(helpRequests: [FamilyHelpRequest(id: UUID(), sentAt: Date(), mgdl: mgdl)]))
            return true
        } catch {
            Log.family.error("Help request failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    /// Turns sharing on and returns the iCloud share to invite family to.
    func startSharing() async throws -> CKShare? {
        guard let cloud else { return nil }
        isWorking = true
        defer { isWorking = false }
        let share = try await cloud.share(title: String(localized: "\(makeProfile().displayName)'s DiabetesCare"))
        settings.familySharingEnabled = true
        await publishNow()
        return share
    }

    func stopSharing() async {
        isWorking = true
        defer { isWorking = false }
        settings.familySharingEnabled = false
        publishTask?.cancel()
        do {
            try await cloud?.stopSharing()
        } catch {
            lastError = error.localizedDescription
        }
        try? FileManager.default.removeItem(at: Self.fingerprintsURL)
        publishedProfile = nil
        lastPublished = nil
        defaults.removeObject(forKey: Key.lastPublished)
    }

    var cloudContainer: CKContainer? { cloud?.container }

    private var publishedProfile: FamilyProfile? {
        get { defaults.data(forKey: Key.publishedProfile).flatMap { try? JSONDecoder().decode(FamilyProfile.self, from: $0) } }
        set { defaults.set(newValue.flatMap { try? JSONEncoder().encode($0) }, forKey: Key.publishedProfile) }
    }

    static var fingerprintsURL: URL {
        FamilyStore.storeURL(for: "published").deletingPathExtension().appendingPathExtension("json")
    }

    // MARK: - Follower

    /// Accepts an iCloud invitation and loads what's shared.
    func accept(_ metadata: CKShare.Metadata) async {
        guard let cloud else { return }
        do {
            try await cloud.accept(metadata)
            try? await cloud.subscribeToSharedChanges()
            UIApplication.shared.registerForRemoteNotifications()
            await refreshFollowed()
        } catch {
            lastError = error.localizedDescription
            Log.family.error("Couldn't accept family share: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Pulls new data for everyone followed and sends any alerts due.
    func refreshFollowed(now: Date = Date()) async {
        guard let transport else { return }
        do {
            let ids = try await transport.followedPersonIDs()
            for id in ids where !followed.contains(where: { $0.id == id }) {
                followed.insert(FamilyPerson(id: id), at: 0)
            }
            for id in ids {
                try await refresh(personID: id, from: transport, now: now)
            }
            saveFollowed()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            Log.family.error("Family refresh failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func refresh(personID: String, from transport: FamilyTransport, now: Date) async throws {
        var tokens = defaults.dictionary(forKey: Key.tokens) as? [String: Data] ?? [:]
        let (changes, token) = try await transport.fetchChanges(for: personID, since: tokens[personID])
        let store = store(for: personID)
        try await Self.apply(changes, to: store.container)

        if let index = followed.firstIndex(where: { $0.id == personID }) {
            if let profile = changes.profile { followed[index].profile = profile }
            followed[index].lastSync = now
            if let profile = followed[index].profile {
                notify(for: followed[index], profile: profile, context: store.container.viewContext, help: changes.helpRequests, now: now)
            }
        }
        tokens[personID] = token
        defaults.set(tokens, forKey: Key.tokens)
    }

    nonisolated static func apply(_ changes: FamilyChangeSet, to container: NSPersistentContainer) async throws {
        let context = container.newBackgroundContext()
        let ids = try await context.perform { try FamilyStore.apply(changes, in: context) }
        await MainActor.run {
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: [NSInsertedObjectsKey: ids.inserted, NSDeletedObjectsKey: ids.deleted],
                into: [container.viewContext]
            )
        }
    }

    private func notify(for person: FamilyPerson, profile: FamilyProfile, context: NSManagedObjectContext, help: [FamilyHelpRequest], now: Date) {
        let key = Key.alertState(person.id)
        let state = defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(CaregiverAlertState.self, from: $0) } ?? CaregiverAlertState()
        let result = policy.evaluate(samples: Self.recentSamples(in: context, now: now), profile: profile, helpRequests: help, state: state, now: now)
        defaults.set(try? JSONEncoder().encode(result.state), forKey: key)
        for alert in result.alerts {
            NotificationService.shared.deliverFamilyAlert(alert, name: person.displayName, personID: person.id)
        }
    }

    /// The latest reading and the hour before it.
    static func recentSamples(in context: NSManagedObjectContext, now: Date) -> [GlucoseSample] {
        let request: NSFetchRequest<GlucoseReading> = GlucoseReading.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp <= %@", now as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReading.timestamp, ascending: false)]
        request.fetchLimit = 30
        let samples = ((try? context.fetch(request)) ?? []).compactMap(\.sample)
        guard let latest = samples.first else { return [] }
        return samples.filter { latest.date.timeIntervalSince($0.date) <= 3600 }
    }

    /// The read-only store holding one followed person's data.
    func store(for personID: String) -> PersistenceController {
        if let store = stores[personID] { return store }
        let store = PersistenceController(storeURL: FamilyStore.storeURL(for: personID))
        stores[personID] = store
        return store
    }

    /// Stops showing someone here. Leaving their iCloud share is done in
    /// iCloud settings or by them stopping sharing.
    func unfollow(_ person: FamilyPerson) {
        followed.removeAll { $0.id == person.id }
        stores[person.id] = nil
        FamilyStore.removeStore(for: person.id)
        var tokens = defaults.dictionary(forKey: Key.tokens) as? [String: Data] ?? [:]
        tokens[person.id] = nil
        defaults.set(tokens, forKey: Key.tokens)
        defaults.removeObject(forKey: Key.alertState(person.id))
        saveFollowed()
    }

    private func addFollowed(_ person: FamilyPerson) {
        followed.removeAll { $0.id == person.id }
        followed.insert(person, at: 0)
        saveFollowed()
    }

    private func saveFollowed() {
        defaults.set(try? JSONEncoder().encode(followed), forKey: Key.followed)
    }

    // MARK: - Preview

    /// What a family member would see right now, built by running this
    /// phone's data through the same publish → fetch → apply path, in
    /// memory. Nothing leaves the phone.
    func makePreview() async throws -> (person: FamilyPerson, store: PersistenceController) {
        guard let container else { throw CocoaError(.featureUnsupported) }
        let loopback = LoopbackFamilyTransport()
        let scratch = FileManager.default.temporaryDirectory.appending(path: "family-preview-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: scratch) }
        let profile = makeProfile()
        try await Self.publish(from: container, profile: profile, previousProfile: nil, fingerprintsURL: scratch, to: loopback)
        // Batch inserts need a real SQLite file; it's temporary.
        let store = PersistenceController(storeURL: FileManager.default.temporaryDirectory.appending(path: "family-preview-\(UUID().uuidString).sqlite"))
        let (changes, _) = try await loopback.fetchChanges(for: LoopbackFamilyTransport.personID, since: nil)
        try await Self.apply(changes, to: store.container)
        let person = FamilyPerson(id: LoopbackFamilyTransport.personID, profile: changes.profile ?? profile, lastSync: Date())
        return (person, store)
    }
}

#if DEBUG
extension FamilyService {
    /// Follows a made-up person whose data is run through the real
    /// publish → fetch → apply path. For `-demoFamily` only.
    func installDemoPerson(from source: NSPersistentContainer, profile: FamilyProfile) async throws {
        let id = DemoData.demoPersonID
        unfollow(FamilyPerson(id: id))
        let loopback = LoopbackFamilyTransport()
        let scratch = FileManager.default.temporaryDirectory.appending(path: "demo-prints-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: scratch) }
        try await Self.publish(from: source, profile: profile, previousProfile: nil, fingerprintsURL: scratch, to: loopback)
        let (changes, _) = try await loopback.fetchChanges(for: LoopbackFamilyTransport.personID, since: nil)
        try await Self.apply(changes, to: store(for: id).container)
        addFollowed(FamilyPerson(id: id, profile: profile, lastSync: Date()))
    }
}
#endif

extension FamilyProfile {
    /// Equal apart from when it was made.
    nonisolated func sameContent(as other: FamilyProfile) -> Bool {
        var a = self, b = other
        a.updatedAt = .distantPast
        b.updatedAt = .distantPast
        return a == b
    }
}
