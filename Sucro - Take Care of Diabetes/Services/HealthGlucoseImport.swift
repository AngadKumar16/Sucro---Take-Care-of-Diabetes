//
//  HealthGlucoseImport.swift
//  Sucro - Take Care of Diabetes
//
//  Pure steps of the Apple Health glucose import, kept apart from HealthKit
//  and Core Data so they can be unit tested.
//

import Foundation

nonisolated enum HealthGlucoseImport {
    /// A glucose sample read from Apple Health, already in mg/dL.
    struct Sample: Equatable, Sendable {
        let uuid: UUID
        let date: Date
        let mgdl: Double
        let sourceName: String
    }

    /// How far back the first import reaches.
    static let backfill: TimeInterval = 30 * 24 * 3600

    /// Incoming samples that aren't stored yet, oldest first, with duplicate
    /// UUIDs in the batch dropped.
    static func newSamples(_ incoming: [Sample], existingIDs: Set<UUID>) -> [Sample] {
        var seen = existingIDs
        return incoming
            .sorted { $0.date < $1.date }
            .filter { seen.insert($0.uuid).inserted }
    }

    /// Trend arrow for each new sample (same order as `new`, which must be
    /// oldest first), measured against everything before it: the stored
    /// readings in `earlier` plus the new samples that come before it. `nil`
    /// where there isn't a continuous trace.
    static func trends(for new: [GlucoseSample], earlier: [GlucoseSample]) -> [GlucoseTrend?] {
        let all = (earlier + new).sorted { $0.date < $1.date }
        // Slide a window over `all`: [start, end) holds the readings from
        // `trendWindow` before each sample up to and including it.
        var start = 0
        var end = 0
        return new.map { sample in
            while end < all.count, all[end].date <= sample.date { end += 1 }
            while start < end, sample.date.timeIntervalSince(all[start].date) > GlucoseCalculator.trendWindow { start += 1 }
            return GlucoseCalculator.trend(samples: Array(all[start..<end]))
        }
    }
}
