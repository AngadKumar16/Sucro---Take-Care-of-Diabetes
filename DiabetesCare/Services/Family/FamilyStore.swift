//
//  FamilyStore.swift
//  DiabetesCare
//
//  Core Data side of family sharing. The publisher reads what to share
//  from the main store; a follower writes what arrives into a separate,
//  read-only store per person, so a parent's own log never mixes with
//  their kid's.
//

import CoreData
import Foundation

nonisolated enum FamilyStore {
    /// The shareable entries from the last `days` days. Call inside
    /// `context.perform`.
    static func shareableArchive(in context: NSManagedObjectContext, stage: CareStage, days: Int = FamilySharing.historyDays, now: Date = Date()) throws -> BackupArchive {
        let archive = try BackupStore.makeArchive(in: context, settings: nil, appVersion: AppInfo.version, now: now)
        let start = now.addingTimeInterval(-Double(days) * 86_400)
        func recent(_ date: Date?) -> Bool { (date ?? .distantPast) >= start }
        var recentOnly = archive
        recentOnly.glucose = archive.glucose.filter { recent($0.timestamp) }
        recentOnly.carbs = archive.carbs.filter { recent($0.timestamp) }
        recentOnly.insulin = archive.insulin.filter { recent($0.timestamp) }
        recentOnly.activity = archive.activity.filter { recent($0.timestamp) }
        recentOnly.sites = archive.sites.filter { recent($0.timestamp) }
        return FamilyDiff.shareable(recentOnly, stage: stage)
    }

    /// Applies a change set to a follower's store: edited entries replace
    /// the old copy, deleted ones go. Call inside `context.perform`.
    /// Returns the object ids touched, for merging into the view context.
    @discardableResult
    static func apply(_ changes: FamilyChangeSet, in context: NSManagedObjectContext) throws -> (inserted: [NSManagedObjectID], deleted: [NSManagedObjectID]) {
        let entries = changes.entries
        let replaced = Array(FamilyDiff.fingerprints(of: entries).keys)
        let removeIDs: [UUID] = replaced + changes.deletedIDs

        var deleted: [NSManagedObjectID] = []
        if !removeIDs.isEmpty {
            for entity in BackupStore.entityNames {
                // Chunk so the IN list stays a sensible size.
                for chunk in stride(from: 0, to: removeIDs.count, by: 500).map({ Array(removeIDs[$0..<min($0 + 500, removeIDs.count)]) }) {
                    let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
                    fetch.predicate = NSPredicate(format: "id IN %@", chunk)
                    let request = NSBatchDeleteRequest(fetchRequest: fetch)
                    request.resultType = .resultTypeObjectIDs
                    let result = try context.execute(request) as? NSBatchDeleteResult
                    deleted += result?.result as? [NSManagedObjectID] ?? []
                }
            }
        }
        let result = try BackupStore.restore(entries, mode: .merge, in: context)
        return (result.inserted, deleted)
    }

    /// Where a followed person's store lives.
    static func storeURL(for personID: String) -> URL {
        let base = URL.applicationSupportDirectory.appending(path: "Family", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        let safe = personID.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        return base.appending(path: "\(safe).sqlite")
    }

    static func removeStore(for personID: String) {
        let url = storeURL(for: personID)
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + suffix))
        }
    }
}
