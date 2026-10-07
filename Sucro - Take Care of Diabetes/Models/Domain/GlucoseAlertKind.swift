//
//  GlucoseAlertKind.swift
//  Sucro - Take Care of Diabetes
//

import Foundation

nonisolated enum GlucoseAlertKind: String, Codable, Sendable {
    case urgentLow
    case low
    case urgentHigh

    init?(zone: GlucoseZone) {
        switch zone {
        case .urgentLow: self = .urgentLow
        case .low: self = .low
        case .urgentHigh: self = .urgentHigh
        case .inRange, .high: return nil
        }
    }
}
