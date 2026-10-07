//
//  GlucoseThresholds.swift
//  Sucro - Take Care of Diabetes
//
//  One source of truth for classifying a glucose value. Colors, the
//  Home banner, notifications and statistics all go through `zone(for:)`.
//

import Foundation

/// The user's glucose thresholds in mg/dL, ordered
/// `urgentLow < targetLow < targetHigh < urgentHigh`.
nonisolated struct GlucoseThresholds: Equatable, Sendable {
    var urgentLow: Double
    var targetLow: Double
    var targetHigh: Double
    var urgentHigh: Double

    static let standard = GlucoseThresholds(urgentLow: 55, targetLow: 70, targetHigh: 180, urgentHigh: 250)

    /// Boundary values belong to the less severe zone: exactly `targetLow`
    /// or `targetHigh` is in range, exactly `urgentHigh` is high.
    func zone(for mgdl: Double) -> GlucoseZone {
        if mgdl < urgentLow { return .urgentLow }
        if mgdl < targetLow { return .low }
        if mgdl > urgentHigh { return .urgentHigh }
        if mgdl > targetHigh { return .high }
        return .inRange
    }
}
