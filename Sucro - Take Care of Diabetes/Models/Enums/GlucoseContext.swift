//
//  GlucoseContext.swift
//  Sucro - Take Care of Diabetes
//

import Foundation

/// When a fingerstick reading was taken. `rawValue` is what readings store
/// in `GlucoseReading.context`.
nonisolated enum GlucoseContext: String, CaseIterable, Sendable {
    case fasting = "Fasting"
    case beforeMeal = "Before Meal"
    case afterMeal = "After Meal"
    case bedtime = "Bedtime"
    case exercise = "Exercise"
    case other = "Other"

    init?(stored: String?) {
        guard let key = stored?.trimmingCharacters(in: .whitespaces).lowercased(), !key.isEmpty else {
            return nil
        }
        guard let match = Self.allCases.first(where: { $0.rawValue.lowercased() == key }) else {
            return nil
        }
        self = match
    }

    /// A sensible starting choice for a reading taken at this time.
    static func likely(at date: Date, calendar: Calendar = .current) -> GlucoseContext {
        switch calendar.component(.hour, from: date) {
        case 4..<9: return .fasting
        case 21..., 0..<4: return .bedtime
        default: return .beforeMeal
        }
    }
}
