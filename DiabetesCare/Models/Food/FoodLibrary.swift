//
//  FoodLibrary.swift
//  DiabetesCare
//
//  The person's own foods: ones they added, packaged foods they scanned,
//  and what they picked recently, so the usual breakfast is one tap away.
//

import Foundation
import Observation

@MainActor
@Observable
final class FoodLibrary {
    static let shared = FoodLibrary()

    @ObservationIgnored private let defaults: UserDefaults
    private static let savedKey = "food.saved"
    private static let recentKey = "food.recent"
    private static let recentLimit = 12

    /// Foods added by hand and scanned packages.
    private(set) var saved: [FoodItem] = []
    /// Recently used, newest first.
    private(set) var recent: [FoodItem] = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        saved = Self.read(defaults, Self.savedKey)
        recent = Self.read(defaults, Self.recentKey)
    }

    func add(_ food: FoodItem) {
        saved.removeAll { $0.id == food.id }
        saved.insert(food, at: 0)
        write(saved, Self.savedKey)
    }

    func remove(_ food: FoodItem) {
        saved.removeAll { $0.id == food.id }
        recent.removeAll { $0.id == food.id }
        write(saved, Self.savedKey)
        write(recent, Self.recentKey)
    }

    func used(_ food: FoodItem) {
        recent.removeAll { $0.id == food.id }
        recent.insert(food, at: 0)
        recent = Array(recent.prefix(Self.recentLimit))
        write(recent, Self.recentKey)
    }

    /// A food the person typed in: carbs for one serving of a given size.
    static func custom(name: String, carbs: Double, servingName: String, servingGrams: Double?) -> FoodItem {
        // Without a weight, treat "1 serving" as 100 g so the math still works.
        let grams = servingGrams.flatMap { $0 > 0 ? $0 : nil } ?? 100
        return FoodItem(
            id: "mine.\(UUID().uuidString)",
            name: name,
            carbsPer100g: carbs / grams * 100,
            fiberPer100g: 0,
            portions: [FoodPortion(name: servingName.isEmpty ? String(localized: "1 serving") : servingName, grams: grams)],
            source: .mine
        )
    }

    private static func read(_ defaults: UserDefaults, _ key: String) -> [FoodItem] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([FoodItem].self, from: data)) ?? []
    }

    private func write(_ foods: [FoodItem], _ key: String) {
        if let data = try? JSONEncoder().encode(foods) { defaults.set(data, forKey: key) }
    }
}
