//
//  SiteRotation.swift
//  DiabetesCare
//
//  How sites have been used over time: when each was last used, and how
//  long each site change was worn before the next one.
//

import Foundation

nonisolated enum SiteRotation {
    struct Change: Equatable {
        var location: SiteLocation
        var date: Date
    }

    struct Wear: Equatable {
        var change: Change
        /// When the next site change replaced this one; nil while in use.
        var endedAt: Date?

        func wornDays(now: Date) -> Double {
            (endedAt ?? now).timeIntervalSince(change.date) / 86_400
        }

        /// Worn noticeably past its rotation days (more than half a day over).
        func wasOverdue(now: Date) -> Bool {
            wornDays(now: now) > Double(change.location.rotationDays) + 0.5
        }
    }

    /// The most recent date each site was used.
    static func lastUsed(_ changes: [Change]) -> [SiteLocation: Date] {
        changes.reduce(into: [:]) { result, change in
            if let date = result[change.location], date >= change.date { return }
            result[change.location] = change.date
        }
    }

    /// Every change, newest first, with when it ended.
    static func wear(_ changes: [Change]) -> [Wear] {
        let sorted = changes.sorted { $0.date > $1.date }
        return sorted.indices.map { index in
            Wear(change: sorted[index], endedAt: index > 0 ? sorted[index - 1].date : nil)
        }
    }

    /// Body-map sites, longest rested first; never-used sites come first.
    static func restOrder(_ lastUsed: [SiteLocation: Date]) -> [SiteLocation] {
        SiteLocation.allCases
            .filter { $0 != .other }
            .sorted { (lastUsed[$0] ?? .distantPast) < (lastUsed[$1] ?? .distantPast) }
    }
}

extension SiteChange {
    var rotationChange: SiteRotation.Change? {
        guard let location = SiteLocation(stored: location), let timestamp else { return nil }
        return SiteRotation.Change(location: location, date: timestamp)
    }
}
