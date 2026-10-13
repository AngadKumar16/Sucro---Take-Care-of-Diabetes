//
//  LowTreatmentAttributes.swift
//  DiabetesCare (shared with the widgets)
//
//  The Live Activity shown while a low is being treated: a countdown to
//  the 15-minute recheck on the Lock Screen and in the Dynamic Island,
//  then the newest reading, until glucose is back in range.
//

#if os(iOS)
import ActivityKit
import Foundation

nonisolated struct LowTreatmentAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable, Sendable {
        enum Phase: String, Codable, Hashable, Sendable {
            /// Waiting out the 15 minutes.
            case waiting
            /// Time to check again.
            case recheck
            /// Back at or above the Low line.
            case recovered
        }

        var phase: Phase
        var recheckAt: Date
        /// The newest reading since treating, mg/dL.
        var latestMgdl: Double?
        var latestAt: Date?
    }

    /// Grams of fast-acting carbs taken.
    var grams: Double
    var startedAt: Date
    /// "mg/dL" or "mmol/L".
    var unit: String
    var targetLow: Double
}

extension LowTreatmentAttributes {
    func value(_ mgdl: Double) -> String {
        unit == "mmol/L"
            ? (mgdl / 18.0182).formatted(.number.precision(.fractionLength(1)))
            : mgdl.formatted(.number.precision(.fractionLength(0)))
    }
}
#endif
