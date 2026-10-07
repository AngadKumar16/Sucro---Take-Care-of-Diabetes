//
//  AlertState.swift
//  Sucro - Take Care of Diabetes
//

import Foundation

/// What the alert logic remembers between evaluations. Persisted so that
/// relaunching the app doesn't re-notify for an event already reported.
nonisolated struct AlertState: Codable, Equatable, Sendable {
    /// The glucose event currently in progress, if any. A notification is
    /// only sent when this changes, i.e. when a threshold is crossed.
    var activeEpisode: GlucoseAlertKind?
    /// When each kind last produced a notification, for the cooldown.
    var lastNotified: [GlucoseAlertKind: Date] = [:]
    /// Timestamp of the reading we already sent a "no recent readings"
    /// notification for, so it goes out once per gap.
    var staleNotifiedForReading: Date?
}
