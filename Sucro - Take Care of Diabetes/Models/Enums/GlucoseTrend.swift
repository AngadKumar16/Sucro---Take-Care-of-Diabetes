//
//  GlucoseTrend.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation

enum GlucoseTrend: String, CaseIterable, Codable {
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
