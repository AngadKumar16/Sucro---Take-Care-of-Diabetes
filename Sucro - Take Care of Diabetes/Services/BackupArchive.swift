//
//  BackupArchive.swift
//  Sucro - Take Care of Diabetes
//
//  A complete backup as one JSON file: every logged entry (site photos
//  included) plus the settings that change how they read. Entries keep
//  their ids, so restoring the same file twice adds nothing the second time
//  and readings from Apple Health stay matched to their Health samples.
//

import CoreData
import Foundation

nonisolated struct BackupArchive: Codable, Equatable, Sendable {
    static let currentVersion = 1

    var version = Self.currentVersion
    var exportedAt: Date
    var appVersion: String
    var settings: Settings?
    var glucose: [Glucose] = []
    var carbs: [Carb] = []
    var insulin: [Insulin] = []
    var activity: [Activity] = []
    var sites: [Site] = []

    var entryCount: Int {
        glucose.count + carbs.count + insulin.count + activity.count + sites.count
    }

    struct Settings: Codable, Equatable, Sendable {
        var userName: String
        var diabetesType: String
        var glucoseUnit: String
        var urgentLow: Double
        var targetLow: Double
        var targetHigh: Double
        var urgentHigh: Double
        var insulinActionHours: Double
        var appearance: String
    }

    struct Glucose: Codable, Equatable, Sendable {
        var id: UUID
        var timestamp: Date?
        var value: Double
        var unit: String?
        var trend: String?
        var source: String?
        var context: String?
        var notes: String?
    }

    struct Carb: Codable, Equatable, Sendable {
        var id: UUID
        var timestamp: Date?
        var grams: Double
        var mealType: String?
        var foodItems: String?
        var notes: String?
    }

    struct Insulin: Codable, Equatable, Sendable {
        var id: UUID
        var timestamp: Date?
        var units: Double
        var type: String?
        var deliveryMethod: String?
        var notes: String?
    }

    struct Activity: Codable, Equatable, Sendable {
        var id: UUID
        var timestamp: Date?
        var type: String?
        var duration: Int16
        var intensity: String?
        var caloriesBurned: Double
        var notes: String?
    }

    struct Site: Codable, Equatable, Sendable {
        var id: UUID
        var timestamp: Date?
        var location: String?
        var siteType: String?
        var deviceType: String?
        var notes: String?
        var photo: Data?
    }

    enum ReadError: LocalizedError {
        case newerVersion(Int)
        case notABackup

        var errorDescription: String? {
            switch self {
            case .newerVersion:
                "This backup was made by a newer version of \(AppInfo.name). Update the app, then try again."
            case .notABackup:
                "This file isn't a \(AppInfo.name) backup."
            }
        }
    }

    // MARK: - JSON

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> BackupArchive {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        // Check the version first so a newer file gets a useful message
        // instead of a decoding error about a field we don't know.
        guard let header = try? decoder.decode(Header.self, from: data) else {
            throw ReadError.notABackup
        }
        guard header.version <= currentVersion else {
            throw ReadError.newerVersion(header.version)
        }
        do {
            return try decoder.decode(BackupArchive.self, from: data)
        } catch {
            throw ReadError.notABackup
        }
    }

    private struct Header: Decodable {
        var version: Int
    }
}

// MARK: - Core Data

/// Reads and writes archives. Call inside `context.perform` on a
/// background context.
nonisolated enum BackupStore {
    enum Mode: Sendable {
        /// Add entries whose id isn't stored yet; keep everything else.
        case merge
        /// Delete everything first, then add every entry.
        case replace
    }

    struct Result {
        var added = 0
        var skipped = 0
        var inserted: [NSManagedObjectID] = []
        var deleted: [NSManagedObjectID] = []
    }

    static let entityNames = ["GlucoseReading", "CarbEntry", "InsulinEntry", "ActivityEntry", "SiteChange"]

    static func makeArchive(in context: NSManagedObjectContext, settings: BackupArchive.Settings?, appVersion: String, now: Date = Date()) throws -> BackupArchive {
        var archive = BackupArchive(exportedAt: now, appVersion: appVersion, settings: settings)
        archive.glucose = try fetch(GlucoseReading.self, in: context).compactMap { r in
            guard let id = r.id else { return nil }
            return .init(id: id, timestamp: r.timestamp, value: r.value, unit: r.unit, trend: r.trend, source: r.source, context: r.context, notes: r.notes)
        }
        archive.carbs = try fetch(CarbEntry.self, in: context).compactMap { c in
            guard let id = c.id else { return nil }
            return .init(id: id, timestamp: c.timestamp, grams: c.grams, mealType: c.mealType, foodItems: c.foodItems, notes: c.notes)
        }
        archive.insulin = try fetch(InsulinEntry.self, in: context).compactMap { i in
            guard let id = i.id else { return nil }
            return .init(id: id, timestamp: i.timestamp, units: i.units, type: i.type, deliveryMethod: i.deliveryMethod, notes: i.notes)
        }
        archive.activity = try fetch(ActivityEntry.self, in: context).compactMap { a in
            guard let id = a.id else { return nil }
            return .init(id: id, timestamp: a.timestamp, type: a.type, duration: a.duration, intensity: a.intensity, caloriesBurned: a.caloriesBurned, notes: a.notes)
        }
        archive.sites = try fetch(SiteChange.self, in: context).compactMap { s in
            guard let id = s.id else { return nil }
            return .init(id: id, timestamp: s.timestamp, location: s.location, siteType: s.siteType, deviceType: s.deviceType, notes: s.notes, photo: s.photo)
        }
        return archive
    }

    static func restore(_ archive: BackupArchive, mode: Mode, in context: NSManagedObjectContext) throws -> Result {
        var result = Result()
        if mode == .replace {
            for name in entityNames + ["DeviceStatus"] {
                let request = NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: name))
                request.resultType = .resultTypeObjectIDs
                let outcome = try context.execute(request) as? NSBatchDeleteResult
                result.deleted += outcome?.result as? [NSManagedObjectID] ?? []
            }
        }

        func insert(_ entity: String, ids: [UUID], rows: [[String: Any]]) throws {
            let existing = mode == .replace ? [] : try storedIDs(entity, in: context)
            var seen = existing
            var new: [[String: Any]] = []
            for (id, row) in zip(ids, rows) where seen.insert(id).inserted {
                new.append(row)
            }
            result.skipped += rows.count - new.count
            guard !new.isEmpty else { return }
            let request = NSBatchInsertRequest(entityName: entity, objects: new)
            request.resultType = .objectIDs
            let outcome = try context.execute(request) as? NSBatchInsertResult
            let inserted = outcome?.result as? [NSManagedObjectID] ?? []
            result.inserted += inserted
            result.added += new.count
        }

        try insert("GlucoseReading", ids: archive.glucose.map(\.id), rows: archive.glucose.map { g in
            row(["id": g.id, "value": g.value], ["timestamp": g.timestamp, "unit": g.unit, "trend": g.trend, "source": g.source, "context": g.context, "notes": g.notes])
        })
        try insert("CarbEntry", ids: archive.carbs.map(\.id), rows: archive.carbs.map { c in
            row(["id": c.id, "grams": c.grams], ["timestamp": c.timestamp, "mealType": c.mealType, "foodItems": c.foodItems, "notes": c.notes])
        })
        try insert("InsulinEntry", ids: archive.insulin.map(\.id), rows: archive.insulin.map { i in
            row(["id": i.id, "units": i.units], ["timestamp": i.timestamp, "type": i.type, "deliveryMethod": i.deliveryMethod, "notes": i.notes])
        })
        try insert("ActivityEntry", ids: archive.activity.map(\.id), rows: archive.activity.map { a in
            row(["id": a.id, "duration": a.duration, "caloriesBurned": a.caloriesBurned], ["timestamp": a.timestamp, "type": a.type, "intensity": a.intensity, "notes": a.notes])
        })
        try insert("SiteChange", ids: archive.sites.map(\.id), rows: archive.sites.map { s in
            row(["id": s.id], ["timestamp": s.timestamp, "location": s.location, "siteType": s.siteType, "deviceType": s.deviceType, "notes": s.notes, "photo": s.photo])
        })
        return result
    }

    /// A batch-insert row: required values plus whichever optionals are set.
    private static func row(_ values: [String: Any], _ optionals: [String: Any?]) -> [String: Any] {
        optionals.reduce(into: values) { row, pair in
            if let value = pair.value { row[pair.key] = value }
        }
    }

    private static func fetch<T: NSManagedObject>(_ type: T.Type, in context: NSManagedObjectContext) throws -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return try context.fetch(request)
    }

    private static func storedIDs(_ entity: String, in context: NSManagedObjectContext) throws -> Set<UUID> {
        let request = NSFetchRequest<NSDictionary>(entityName: entity)
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["id"]
        return Set(try context.fetch(request).compactMap { $0["id"] as? UUID })
    }
}
