//
//  MealType.swift
//  Sucro - Take Care of Diabetes
//

import Foundation

/// The meal a `CarbEntry` belongs to. `rawValue` is what entries store in
/// `CarbEntry.mealType`.
nonisolated enum MealType: String, CaseIterable, Sendable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    case other = "Other"

    /// Reads a stored value, including the lowercase tags older edit
    /// screens saved ("breakfast", "snack", ...).
    init?(stored: String?) {
        guard let key = stored?.trimmingCharacters(in: .whitespaces).lowercased(), !key.isEmpty else {
            return nil
        }
        guard let match = Self.allCases.first(where: { $0.rawValue.lowercased() == key }) else {
            return nil
        }
        self = match
    }

    /// The meal people are most likely logging at this time of day.
    static func likely(at date: Date, calendar: Calendar = .current) -> MealType {
        switch calendar.component(.hour, from: date) {
        case 5..<11: return .breakfast
        case 11..<15: return .lunch
        case 17..<22: return .dinner
        default: return .snack
        }
    }
}
