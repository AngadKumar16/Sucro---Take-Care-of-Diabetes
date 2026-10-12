//
//  CaregiverAlertPolicy.swift
//  DiabetesCare
//
//  Which alerts reach a parent's phone. A kid's parent hears about every
//  low and high, a gap in CGM data, and help requests. A teen's parent only
//  hears the urgent ones, so the teen stays in charge. An adult who shares
//  sends only urgent lows. Pure, so it can be tested.
//

import Foundation

nonisolated enum CaregiverAlert: Equatable, Sendable {
    case glucose(GlucoseAlertKind, mgdl: Double)
    case noRecentData(lastReading: Date)
    case helpRequested(FamilyHelpRequest)
}

nonisolated struct CaregiverAlertState: Codable, Equatable, Sendable {
    var glucose = AlertState()
    /// Help requests already notified.
    var notifiedHelpIDs: [UUID] = []
}

nonisolated struct CaregiverAlertPolicy: Sendable {
    var glucosePolicy = GlucoseAlertPolicy()
    /// Help requests older than this are history, not alerts.
    var helpFreshness: TimeInterval = 30 * 60

    static func kinds(for stage: CareStage) -> Set<GlucoseAlertKind> {
        switch stage {
        case .kid: [.urgentLow, .low, .urgentHigh]
        case .teen: [.urgentLow, .urgentHigh]
        case .adult: [.urgentLow]
        }
    }

    func evaluate(samples: [GlucoseSample], profile: FamilyProfile, helpRequests: [FamilyHelpRequest], state: CaregiverAlertState, now: Date) -> (alerts: [CaregiverAlert], state: CaregiverAlertState) {
        var state = state
        var alerts: [CaregiverAlert] = []

        // Glucose: the same crossing rules as on the person's own phone,
        // so a parent is never told twice about one low.
        let latest = samples.max { $0.date < $1.date }
        let decision = glucosePolicy.evaluateGlucose(latest: latest, thresholds: profile.thresholds, state: state.glucose, now: now)
        state.glucose = decision.state
        if let kind = decision.notify, let latest, Self.kinds(for: profile.stage).contains(kind) {
            alerts.append(.glucose(kind, mgdl: latest.mgdl))
        }

        // Missing CGM data, for kids only.
        if profile.stage == .kid, let deadline = glucosePolicy.staleDeadline(for: samples), deadline <= now, let latest,
           state.glucose.staleNotifiedForReading != latest.date {
            state.glucose.staleNotifiedForReading = latest.date
            alerts.append(.noRecentData(lastReading: latest.date))
        }

        // Help requests, once each, while they're recent.
        for request in helpRequests.sorted(by: { $0.sentAt < $1.sentAt })
        where !state.notifiedHelpIDs.contains(request.id) && now.timeIntervalSince(request.sentAt) <= helpFreshness {
            state.notifiedHelpIDs.append(request.id)
            alerts.append(.helpRequested(request))
        }
        state.notifiedHelpIDs = Array(state.notifiedHelpIDs.suffix(50))
        return (alerts, state)
    }
}
