//
//  GlucoseZone.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// Where a glucose value sits relative to the user's thresholds.
nonisolated enum GlucoseZone: Equatable, Sendable {
    case urgentLow
    case low
    case inRange
    case high
    case urgentHigh

    /// Lows always need action. Highs only once they pass the urgent line,
    /// so a mildly high reading doesn't raise an alarm.
    var needsAction: Bool {
        switch self {
        case .urgentLow, .low, .urgentHigh: return true
        case .inRange, .high: return false
        }
    }

    var isLow: Bool { self == .urgentLow || self == .low }

    /// Spoken by VoiceOver and shown when color can't be relied on.
    var name: String {
        switch self {
        case .urgentLow: "Urgent low"
        case .low: "Low"
        case .inRange: "In range"
        case .high: "High"
        case .urgentHigh: "Urgent high"
        }
    }

    var color: Color {
        switch self {
        case .urgentLow, .low, .urgentHigh: return .red
        case .high: return .orange
        case .inRange: return .green
        }
    }
}
