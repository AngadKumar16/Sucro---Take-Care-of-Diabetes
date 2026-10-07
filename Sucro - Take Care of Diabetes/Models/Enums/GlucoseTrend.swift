//
//  GlucoseTrend.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation

nonisolated enum GlucoseTrend: String, CaseIterable, Codable, Sendable {
    case risingFast = "rising_fast"
    case rising = "rising"
    case stable = "stable"
    case falling = "falling"
    case fallingFast = "falling_fast"
    
    var icon: String {
        switch self {
        case .risingFast:
            return "arrow.up.circle.fill"
        case .rising:
            return "arrow.up.right"
        case .stable:
            return "arrow.right"
        case .falling:
            return "arrow.down.right"
        case .fallingFast:
            return "arrow.down.circle.fill"
        }
    }
    
    var colorName: String {
        switch self {
        case .risingFast:
            return "glucoseHigh"
        case .rising:
            return "glucoseRising"
        case .stable:
            return "glucoseNormal"
        case .falling:
            return "glucoseFalling"
        case .fallingFast:
            return "glucoseLow"
        }
    }
    
    /// Reads a stored trend, including the Dexcom-style names older data
    /// and previews used ("up", "doubleDown", "flat", ...).
    init?(stored: String?) {
        guard let key = stored?.lowercased(), !key.isEmpty else { return nil }
        if let trend = GlucoseTrend(rawValue: key) {
            self = trend
            return
        }
        switch key {
        case "doubleup", "risingfast": self = .risingFast
        case "up", "singleup", "fortyfiveup": self = .rising
        case "flat", "notchanging", "steady": self = .stable
        case "down", "singledown", "fortyfivedown": self = .falling
        case "doubledown", "fallingfast": self = .fallingFast
        default: return nil
        }
    }

    var isRising: Bool { self == .rising || self == .risingFast }

    /// Arrow shown next to the current glucose value.
    var arrowSymbol: String {
        switch self {
        case .risingFast: return "arrow.up"
        case .rising: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .falling: return "arrow.down.right"
        case .fallingFast: return "arrow.down"
        }
    }

    var description: String {
        switch self {
        case .risingFast:
            return "Rising Fast"
        case .rising:
            return "Rising"
        case .stable:
            return "Stable"
        case .falling:
            return "Falling"
        case .fallingFast:
            return "Falling Fast"
        }
    }
}
