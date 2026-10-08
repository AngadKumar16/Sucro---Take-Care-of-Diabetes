//
//  HealthGlucoseStore.swift
//  Sucro - Take Care of Diabetes
//

import CoreData
import Foundation

/// The Core Data half of the import, separate so tests can run it against
/// a throwaway store without HealthKit.
nonisolated enum HealthGlucoseStore {
    struct Result {
        var inserted: [NSManagedObjectID] = []
        var deleted: [NSManagedObjectID] = []
        var newestSourceName: String?
    }

    private static let entity = "GlucoseReading"

    /// Inserts new samples (skipping ones already stored), sets their trend,
    /// and deletes readings whose Health sample was deleted. Call inside
    /// `context.perform`. Only readings marked as from Health are deleted.
    static func apply(added: [HealthGlucoseImport.Sample], deleted: [UUID], in context: NSManagedObjectContext) throws -> Result {
        var result = Result()

        if !deleted.isEmpty {
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            fetch.predicate = NSPredicate(format: "source == %@ AND id IN %@", GlucoseSource.health.rawValue, deleted)
            let request = NSBatchDeleteRequest(fetchRequest: fetch)
            request.resultType = .resultTypeObjectIDs
            let outcome = try context.execute(request) as? NSBatchDeleteResult
            result.deleted = outcome?.result as? [NSManagedObjectID] ?? []
        }

        guard !added.isEmpty else { return result }

        let existing = try storedIDs(among: added.map(\.uuid), in: context)
        let new = HealthGlucoseImport.newSamples(added, existingIDs: existing)
        guard let first = new.first, let last = new.last else { return result }

        let stored = try storedSamples(
            from: first.date.addingTimeInterval(-GlucoseCalculator.trendWindow),
            to: last.date,
            in: context
        )
        let trends = HealthGlucoseImport.trends(
            for: new.map { GlucoseSample(date: $0.date, mgdl: $0.mgdl) },
            earlier: stored
        )

        let rows: [[String: Any]] = zip(new, trends).map { sample, trend in
            var row: [String: Any] = [
                "id": sample.uuid,
                "timestamp": sample.date,
                "value": sample.mgdl,
                "unit": "mg/dL",
                "source": GlucoseSource.health.rawValue,
            ]
            if let trend { row["trend"] = trend.rawValue }
            return row
        }
        let insert = NSBatchInsertRequest(entityName: entity, objects: rows)
        insert.resultType = .objectIDs
        let outcome = try context.execute(insert) as? NSBatchInsertResult
        result.inserted = outcome?.result as? [NSManagedObjectID] ?? []
        result.newestSourceName = last.sourceName
        return result
    }

    private static func storedIDs(among ids: [UUID], in context: NSManagedObjectContext) throws -> Set<UUID> {
        let request = NSFetchRequest<NSDictionary>(entityName: entity)
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["id"]
        request.predicate = NSPredicate(format: "id IN %@", ids)
        return Set(try context.fetch(request).compactMap { $0["id"] as? UUID })
    }

    private static func storedSamples(from start: Date, to end: Date, in context: NSManagedObjectContext) throws -> [GlucoseSample] {
        let request = NSFetchRequest<NSDictionary>(entityName: entity)
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["timestamp", "value"]
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", start as NSDate, end as NSDate)
        return try context.fetch(request).compactMap { row in
            guard let date = row["timestamp"] as? Date, let value = row["value"] as? Double else { return nil }
            return GlucoseSample(date: date, mgdl: value)
        }
    }
}
