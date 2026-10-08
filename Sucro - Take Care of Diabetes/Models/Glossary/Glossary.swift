//
//  Glossary.swift
//  Sucro - Take Care of Diabetes
//
//  The glossary terms, loaded once from Resources/Glossary.json, plus
//  lookup and search.
//

import Foundation

nonisolated struct Glossary: Sendable {
    static let shared = Glossary(bundle: .main)

    /// All terms, sorted by name.
    let terms: [GlossaryTerm]
    private let byID: [String: GlossaryTerm]

    /// The terms someone new should read first, in reading order.
    static let startHereIDs = [
        "blood-glucose", "target-range", "time-in-range", "hypoglycemia",
        "rule-of-15", "hyperglycemia", "ketones", "insulin-on-board", "carb-counting",
    ]

    init(terms: [GlossaryTerm]) {
        self.terms = terms.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        self.byID = Dictionary(terms.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    init(bundle: Bundle) {
        guard let url = bundle.url(forResource: "Glossary", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let terms = try? JSONDecoder().decode([GlossaryTerm].self, from: data) else {
            assertionFailure("Glossary.json is missing or invalid")
            self.init(terms: [])
            return
        }
        self.init(terms: terms)
    }

    func term(_ id: String) -> GlossaryTerm? {
        byID[id]
    }

    var startHere: [GlossaryTerm] {
        Self.startHereIDs.compactMap(term)
    }

    func terms(in category: GlossaryCategory) -> [GlossaryTerm] {
        terms.filter { $0.category == category }
    }

    func related(to term: GlossaryTerm) -> [GlossaryTerm] {
        term.related.compactMap(self.term)
    }

    /// Terms grouped by first letter, for the A–Z list.
    var alphabetical: [(letter: String, terms: [GlossaryTerm])] {
        let groups = Dictionary(grouping: terms, by: \.indexLetter)
        return groups.keys.sorted().map { ($0, groups[$0] ?? []) }
    }

    /// Terms matching the query, best matches first: names, then aliases,
    /// then words in the definition.
    func search(_ query: String) -> [GlossaryTerm] {
        let needle = Self.normalize(query)
        guard !needle.isEmpty else { return [] }

        let scored: [(term: GlossaryTerm, score: Int)] = terms.compactMap { term in
            let name = Self.normalize(term.name)
            let aliases = term.aliases.map(Self.normalize)
            let score: Int
            if name == needle || aliases.contains(needle) {
                score = 0
            } else if name.hasPrefix(needle) || name.contains(" \(needle)") {
                score = 1
            } else if aliases.contains(where: { $0.hasPrefix(needle) }) {
                score = 2
            } else if name.contains(needle) || aliases.contains(where: { $0.contains(needle) }) {
                score = 3
            } else if Self.normalize(term.summary).contains(needle) {
                score = 4
            } else if Self.normalize(term.details).contains(needle) {
                score = 5
            } else {
                return nil
            }
            return (term, score)
        }
        return scored
            .sorted { $0.score != $1.score ? $0.score < $1.score : $0.term.name < $1.term.name }
            .map(\.term)
    }

    private static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
