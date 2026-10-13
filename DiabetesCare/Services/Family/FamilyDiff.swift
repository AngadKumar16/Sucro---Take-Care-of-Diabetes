//
//  FamilyDiff.swift
//  DiabetesCare
//
//  Works out what changed since the last publish by comparing a
//  fingerprint of every shared entry. Pure, so it can be tested without
//  Core Data or CloudKit.
//

import CryptoKit
import Foundation

nonisolated enum FamilyDiff {
    /// Entry id → hash of its shared content.
    typealias Fingerprints = [UUID: String]

    /// Strips what isn't shared: photos always; notes unless the person is
    /// a kid. A teen's or adult's notes stay on their phone.
    static func shareable(_ archive: BackupArchive, stage: CareStage) -> BackupArchive {
        var archive = archive
        archive.settings = nil
        archive.sites = archive.sites.map { var s = $0; s.photo = nil; return s }
        archive.carbs = archive.carbs.map { var c = $0; c.photo = nil; return c }
        // Ketones, day tags and supplies stay on this phone.
        archive.ketones = nil
        archive.tags = nil
        archive.kit = nil
        if stage != .kid {
            archive.glucose = archive.glucose.map { var e = $0; e.notes = nil; return e }
            archive.carbs = archive.carbs.map { var e = $0; e.notes = nil; return e }
            archive.insulin = archive.insulin.map { var e = $0; e.notes = nil; return e }
            archive.activity = archive.activity.map { var e = $0; e.notes = nil; return e }
            archive.sites = archive.sites.map { var e = $0; e.notes = nil; return e }
        }
        return archive
    }

    static func fingerprints(of archive: BackupArchive) -> Fingerprints {
        var result: Fingerprints = [:]
        for e in archive.glucose { result[e.id] = hash(e) }
        for e in archive.carbs { result[e.id] = hash(e) }
        for e in archive.insulin { result[e.id] = hash(e) }
        for e in archive.activity { result[e.id] = hash(e) }
        for e in archive.sites { result[e.id] = hash(e) }
        return result
    }

    /// Entries that are new or changed, and ids that were published before
    /// but are gone now.
    static func changes(from previous: Fingerprints, to current: BackupArchive) -> (entries: BackupArchive, deleted: [UUID], fingerprints: Fingerprints) {
        let now = fingerprints(of: current)
        func changed(_ id: UUID) -> Bool { previous[id] != now[id] }
        var entries = current
        entries.glucose = current.glucose.filter { changed($0.id) }
        entries.carbs = current.carbs.filter { changed($0.id) }
        entries.insulin = current.insulin.filter { changed($0.id) }
        entries.activity = current.activity.filter { changed($0.id) }
        entries.sites = current.sites.filter { changed($0.id) }
        let deleted = previous.keys.filter { now[$0] == nil }.sorted { $0.uuidString < $1.uuidString }
        return (entries, deleted, now)
    }

    private static func hash<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = (try? encoder.encode(value)) ?? Data()
        return SHA256.hash(data: data).prefix(12).map { String(format: "%02x", $0) }.joined()
    }
}
