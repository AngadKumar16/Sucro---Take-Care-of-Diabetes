//
//  GlossaryTests.swift
//  Sucro - Take Care of DiabetesTests
//

import Foundation
import Testing
@testable import Sucro___Take_Care_of_Diabetes

@MainActor
struct GlossaryTests {
    let glossary = Glossary(bundle: Bundle(for: PersistenceController.self))

    @Test func loadsFromTheAppBundle() {
        #expect(glossary.terms.count > 100)
        #expect(Set(glossary.terms.map(\.id)).count == glossary.terms.count, "ids must be unique")
    }

    @Test func everyLinkPointsAtARealTerm() {
        for term in glossary.terms {
            for id in term.related {
                #expect(glossary.term(id) != nil, "\(term.id) links to missing \(id)")
            }
            #expect(!term.related.contains(term.id), "\(term.id) links to itself")
        }
        #expect(glossary.startHere.count == Glossary.startHereIDs.count)
    }

    @Test func linksUsedInTheAppExist() {
        // GlossaryLink and the Trends/ketone screens refer to these by id.
        for id in ["target-range", "insulin-action-time", "time-in-range", "average-glucose", "ketones", "dka", "sick-day-rules"] {
            #expect(glossary.term(id) != nil, "\(id) is linked from the app")
        }
    }

    @Test func everyTopicHasTerms() {
        for category in GlossaryCategory.allCases {
            #expect(!glossary.terms(in: category).isEmpty, "\(category) is empty")
        }
    }

    @Test func searchFindsAbbreviationsFirst() {
        #expect(glossary.search("IOB").first?.id == "insulin-on-board")
        #expect(glossary.search("dka").first?.id == "dka")
        #expect(glossary.search("hba1c").first?.id == "a1c")
        #expect(glossary.search("tir").first?.id == "time-in-range")
        #expect(glossary.search("  ").isEmpty)
        #expect(glossary.search("zzzz").isEmpty)
    }

    @Test func searchRanksNamesAboveDefinitions() {
        let results = glossary.search("ketone").map(\.id)
        let nameMatch = results.firstIndex(of: "ketones") ?? .max
        let definitionMatch = results.firstIndex(of: "dka") ?? .max
        #expect(nameMatch < definitionMatch)
    }

    @Test func savedTermsPersist() {
        let suiteName = "SucroTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let term = glossary.term("ketones")!

        let store = SettingsStore(defaults: defaults)
        store.toggleSaved(term)
        #expect(SettingsStore(defaults: defaults).isSaved(term))
        store.toggleSaved(term)
        #expect(!SettingsStore(defaults: defaults).isSaved(term))
    }
}
