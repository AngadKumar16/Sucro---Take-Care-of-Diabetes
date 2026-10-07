//
//  GlucoseAlertPolicy.swift
//  Sucro - Take Care of Diabetes
//
//  Pure rules for when a glucose reading or a CGM gap should notify.
//  No Core Data or notifications here, so it can be unit tested.
//

import Foundation

nonisolated struct GlucoseAlertPolicy: Sendable {
    /// Older readings don't start or change an episode; we don't know what
    /// glucose is doing now.
    var freshness: TimeInterval = 15 * 60
    /// After a notification, the same kind stays quiet this long even if
    /// glucose bounces across the threshold again.
    var cooldown: TimeInterval = 30 * 60
    /// Gap after the last CGM reading before data counts as missing.
    var staleAfter: TimeInterval = 20 * 60
    /// How long a low or urgent high reading keeps the Home banner up when
    /// nothing newer has been logged.
    var bannerFreshness: TimeInterval = 60 * 60

    struct GlucoseDecision: Equatable {
        var notify: GlucoseAlertKind?
        var state: AlertState
    }

    /// Updates the episode for the latest reading and says whether to notify.
    ///
    /// - Entering low, urgent low or urgent high notifies, unless the same
    ///   kind notified within `cooldown`.
    /// - Going from low to urgent low always notifies.
    /// - Staying in the same episode, easing from urgent low to low, or
    ///   returning to range never notifies.
    func evaluateGlucose(latest: GlucoseSample?, thresholds: GlucoseThresholds, state: AlertState, now: Date) -> GlucoseDecision {
        var state = state
        guard let latest, now.timeIntervalSince(latest.date) <= freshness else {
            return GlucoseDecision(notify: nil, state: state)
        }

        let kind = GlucoseAlertKind(zone: thresholds.zone(for: latest.mgdl))
        let previous = state.activeEpisode
        state.activeEpisode = kind

        guard let kind, kind != previous else {
            return GlucoseDecision(notify: nil, state: state)
        }

        let escalated = previous == .low && kind == .urgentLow
        let eased = previous == .urgentLow && kind == .low
        if eased {
            return GlucoseDecision(notify: nil, state: state)
        }

        if !escalated, let last = state.lastNotified[kind], now.timeIntervalSince(last) < cooldown {
            return GlucoseDecision(notify: nil, state: state)
        }

        state.lastNotified[kind] = now
        return GlucoseDecision(notify: kind, state: state)
    }

    /// Whether readings look like a CGM stream: at least three readings in
    /// the hour before the latest one, none more than 15 minutes apart.
    /// Fingerstick-only logs never count, so they never trigger a
    /// "no recent readings" warning.
    func isContinuousStream(_ samples: [GlucoseSample]) -> Bool {
        let sorted = samples.sorted { $0.date < $1.date }
        guard let latest = sorted.last else { return false }
        let window = sorted.filter { latest.date.timeIntervalSince($0.date) <= 3600 }
        guard window.count >= 3 else { return false }
        for (earlier, later) in zip(window, window.dropFirst())
        where later.date.timeIntervalSince(earlier.date) > GlucoseCalculator.trendMaxGap {
            return false
        }
        return true
    }

    /// When CGM data counts as missing, or `nil` if the readings aren't a
    /// CGM stream.
    func staleDeadline(for samples: [GlucoseSample]) -> Date? {
        guard isContinuousStream(samples), let latest = samples.map(\.date).max() else { return nil }
        return latest.addingTimeInterval(staleAfter)
    }
}
