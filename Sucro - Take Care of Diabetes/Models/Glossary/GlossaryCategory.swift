//
//  GlossaryCategory.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// The topics the glossary is grouped into. Raw values match
/// `category` in `Glossary.json`.
nonisolated enum GlossaryCategory: String, Codable, CaseIterable, Sendable {
    case basics
    case glucose
    case lowsHighs
    case insulin
    case food
    case devices
    case medications
    case complications
    case living

    var title: String {
        switch self {
        case .basics: return "Diabetes Basics"
        case .glucose: return "Glucose & Monitoring"
        case .lowsHighs: return "Lows, Highs & Ketones"
        case .insulin: return "Insulin"
        case .food: return "Food & Carbs"
        case .devices: return "Devices & Tech"
        case .medications: return "Other Medicines"
        case .complications: return "Complications & Checkups"
        case .living: return "Everyday Life"
        }
    }

    var symbol: String {
        switch self {
        case .basics: return "book.closed.fill"
        case .glucose: return "drop.fill"
        case .lowsHighs: return "exclamationmark.triangle.fill"
        case .insulin: return "syringe.fill"
        case .food: return "fork.knife"
        case .devices: return "sensor.fill"
        case .medications: return "pills.fill"
        case .complications: return "stethoscope"
        case .living: return "figure.walk"
        }
    }

    var color: Color {
        switch self {
        case .basics: return .indigo
        case .glucose: return .blue
        case .lowsHighs: return .red
        case .insulin: return .green
        case .food: return .orange
        case .devices: return .teal
        case .medications: return .purple
        case .complications: return .pink
        case .living: return .mint
        }
    }
}
