//
//  SpotlightIndexer.swift
//  DiabetesCare
//
//  Puts the glossary and the guides in Spotlight, so searching "ketones"
//  from the Home Screen opens the explanation. Only reference content is
//  indexed, never anything from the log.
//

import CoreSpotlight
import Foundation
import OSLog
import UniformTypeIdentifiers

@MainActor
enum SpotlightIndexer {
    static let termDomain = "glossary"
    static let guideDomain = "guides"
    private static let versionKey = "spotlight.indexedVersion"
    /// Bump when what's indexed changes.
    private static let version = 1

    static func indexIfNeeded(defaults: UserDefaults = .standard) {
        guard defaults.integer(forKey: versionKey) < version else { return }
        var items = Glossary.shared.terms.map { term in
            let attributes = CSSearchableItemAttributeSet(contentType: .text)
            attributes.title = term.name
            attributes.contentDescription = term.summary
            attributes.keywords = term.aliases + [term.category.rawValue, "diabetes"]
            return CSSearchableItem(uniqueIdentifier: "term.\(term.id)", domainIdentifier: termDomain, attributeSet: attributes)
        }
        items += Guide.allCases.map { guide in
            let attributes = CSSearchableItemAttributeSet(contentType: .text)
            attributes.title = guide.title
            attributes.contentDescription = guide.subtitle
            attributes.keywords = ["guide", "diabetes", guide.title]
            return CSSearchableItem(uniqueIdentifier: "guide.\(guide.rawValue)", domainIdentifier: guideDomain, attributeSet: attributes)
        }
        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error {
                Log.data.error("Spotlight indexing failed: \(error.localizedDescription, privacy: .public)")
            } else {
                Task { @MainActor in defaults.set(version, forKey: versionKey) }
            }
        }
    }

    /// The route for a Spotlight result the person tapped.
    static func route(for identifier: String) -> AppRouter.Route? {
        if identifier.hasPrefix("term.") { return .glossaryTerm(String(identifier.dropFirst(5))) }
        if identifier.hasPrefix("guide.") { return .guide(String(identifier.dropFirst(6))) }
        return nil
    }
}
