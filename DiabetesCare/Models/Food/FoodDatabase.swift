//
//  FoodDatabase.swift
//  DiabetesCare
//
//  Carb lookup. The bundled foods come from USDA FoodData Central (FNDDS,
//  public domain), built by scripts/make-food-db.py, so search works with
//  no network. Packaged foods can be looked up by barcode in Open Food
//  Facts when the person turns that on. Every number is an estimate the
//  person can change before saving.
//

import Foundation

nonisolated struct FoodPortion: Codable, Hashable, Sendable {
    var name: String
    var grams: Double
}

nonisolated struct FoodItem: Codable, Hashable, Identifiable, Sendable {
    enum Source: String, Codable, Sendable {
        /// USDA FoodData Central.
        case usda
        /// A package's nutrition label, via Open Food Facts.
        case label
        /// Added by the person.
        case mine
    }

    var id: String
    var name: String
    /// Grams of carbohydrate in 100 g of the food.
    var carbsPer100g: Double
    var fiberPer100g: Double
    var portions: [FoodPortion]
    var source: Source
    var brand: String?

    /// Carbs in `amount` of a portion, rounded to the nearest gram.
    func carbs(portion: FoodPortion, amount: Double) -> Double {
        (carbsPer100g * portion.grams / 100 * amount).rounded()
    }

    /// The portion most people mean: a "medium" or "regular" one if there
    /// is one, otherwise the first listed.
    var defaultPortion: FoodPortion? {
        portions.first { $0.name.localizedCaseInsensitiveContains("medium") || $0.name.localizedCaseInsensitiveContains("regular") }
            ?? portions.first
    }
}

nonisolated enum FoodSearch {
    /// Results for `query`, best first. Every word must appear; a name that
    /// starts with the query beats one that only contains it, and shorter
    /// names (plain "Apple, raw") beat long variations.
    static func search(_ query: String, in foods: [FoodItem], limit: Int = 60) -> [FoodItem] {
        let words = query.lowercased().split(whereSeparator: { $0 == " " || $0 == "," }).map(String.init)
        guard !words.isEmpty else { return [] }
        let phrase = words.joined(separator: " ")
        var scored: [(Int, FoodItem)] = []
        for food in foods {
            let name = food.name.lowercased()
            guard words.allSatisfy(name.contains) else { continue }
            var score = 0
            if name == phrase { score += 1000 }
            if name.hasPrefix(phrase) { score += 500 }
            let nameWords = name.split(whereSeparator: { $0 == " " || $0 == "," })
            if let first = words.first, nameWords.first.map({ $0.hasPrefix(first) }) == true { score += 200 }
            score += words.count(where: { word in nameWords.contains { $0.hasPrefix(word) } }) * 50
            if food.source != .usda { score += 300 }
            score -= min(name.count, 120)
            scored.append((score, food))
        }
        return scored.sorted { $0.0 > $1.0 }.prefix(limit).map(\.1)
    }
}

/// The bundled USDA foods, loaded once off the main thread.
actor FoodDatabase {
    static let shared = FoodDatabase()

    private var foods: [FoodItem]?
    private(set) var sourceName = "USDA FoodData Central"

    private struct File: Decodable {
        struct Row: Decodable {
            let i: Int
            let n: String
            let c: Double
            let f: Double
            let p: [[PortionValue]]
        }
        enum PortionValue: Decodable {
            case text(String)
            case number(Double)
            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let text = try? container.decode(String.self) { self = .text(text) } else { self = .number(try container.decode(Double.self)) }
            }
        }
        let source: String
        let foods: [Row]
    }

    func all() -> [FoodItem] {
        if let foods { return foods }
        let loaded = Self.load(from: Bundle.main.url(forResource: "Foods", withExtension: "json"))
        foods = loaded
        return loaded
    }

    func search(_ query: String) -> [FoodItem] {
        FoodSearch.search(query, in: all())
    }

    static func load(from url: URL?) -> [FoodItem] {
        guard let url, let data = try? Data(contentsOf: url) else { return [] }
        return decode(data)
    }

    static func decode(_ data: Data) -> [FoodItem] {
        guard let file = try? JSONDecoder().decode(File.self, from: data) else { return [] }
        return file.foods.map { row in
            let portions: [FoodPortion] = row.p.compactMap { pair in
                guard pair.count == 2, case .text(let name) = pair[0], case .number(let grams) = pair[1] else { return nil }
                return FoodPortion(name: name, grams: grams)
            }
            return FoodItem(
                id: "usda.\(row.i)",
                name: row.n,
                carbsPer100g: row.c,
                fiberPer100g: row.f,
                portions: portions + [FoodPortion(name: "100 g", grams: 100)],
                source: .usda
            )
        }
    }
}

// MARK: - Open Food Facts

/// Looks up a packaged food by barcode. Only the barcode is sent.
nonisolated enum OpenFoodFacts {
    enum LookupError: LocalizedError {
        case notFound
        case noCarbs
        case network

        var errorDescription: String? {
            switch self {
            case .notFound: String(localized: "That barcode isn't in Open Food Facts yet.")
            case .noCarbs: String(localized: "Open Food Facts doesn't list carbs for this product.")
            case .network: String(localized: "Couldn't reach Open Food Facts. Check your connection.")
            }
        }
    }

    static func url(for barcode: String) -> URL? {
        let digits = barcode.filter(\.isNumber)
        guard (6...14).contains(digits.count) else { return nil }
        return URL(string: "https://world.openfoodfacts.org/api/v2/product/\(digits).json?fields=product_name,brands,nutriments,serving_size,serving_quantity")
    }

    static func lookup(barcode: String, session: URLSession = .shared) async throws -> FoodItem {
        guard let url = url(for: barcode) else { throw LookupError.notFound }
        var request = URLRequest(url: url)
        request.setValue("DiabetesCare/1.0 (iOS; https://github.com/AngadKumar16)", forHTTPHeaderField: "User-Agent")
        let data: Data
        do {
            (data, _) = try await session.data(for: request)
        } catch {
            throw LookupError.network
        }
        return try parse(data, barcode: barcode)
    }

    private struct Response: Decodable {
        struct Product: Decodable {
            let product_name: String?
            let brands: String?
            let nutriments: [String: FlexibleNumber]?
            let serving_size: String?
            let serving_quantity: FlexibleNumber?
        }
        let status: Int?
        let product: Product?
    }

    /// Open Food Facts sends numbers as numbers or strings.
    private struct FlexibleNumber: Decodable {
        let value: Double?
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let number = try? container.decode(Double.self) {
                value = number
            } else if let text = try? container.decode(String.self) {
                value = Double(text)
            } else {
                value = nil
            }
        }
    }

    static func parse(_ data: Data, barcode: String) throws -> FoodItem {
        guard let response = try? JSONDecoder().decode(Response.self, from: data),
              response.status != 0, let product = response.product else { throw LookupError.notFound }
        let nutriments = product.nutriments ?? [:]
        let per100 = nutriments["carbohydrates_100g"]?.value
        let perServing = nutriments["carbohydrates_serving"]?.value
        let servingGrams = product.serving_quantity?.value
        // Prefer per-100 g; work it out from the serving if that's all there is.
        let carbs100: Double
        if let per100 {
            carbs100 = per100
        } else if let perServing, let servingGrams, servingGrams > 0 {
            carbs100 = perServing / servingGrams * 100
        } else {
            throw LookupError.noCarbs
        }
        var portions: [FoodPortion] = []
        if let servingGrams, servingGrams > 0 {
            let label = product.serving_size.map { String(localized: "1 serving (\($0))") } ?? String(localized: "1 serving")
            portions.append(FoodPortion(name: label, grams: servingGrams))
        }
        portions.append(FoodPortion(name: "100 g", grams: 100))
        let name = product.product_name?.trimmingCharacters(in: .whitespaces)
        return FoodItem(
            id: "off.\(barcode.filter(\.isNumber))",
            name: (name?.isEmpty == false ? name : nil) ?? String(localized: "Packaged food"),
            carbsPer100g: (carbs100 * 10).rounded() / 10,
            fiberPer100g: nutriments["fiber_100g"]?.value ?? 0,
            portions: portions,
            source: .label,
            brand: product.brands?.split(separator: ",").first.map { String($0).trimmingCharacters(in: .whitespaces) }
        )
    }
}
