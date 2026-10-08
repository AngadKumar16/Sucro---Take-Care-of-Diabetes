//
//  GlossaryDestination.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// Screens inside the glossary.
enum GlossaryDestination: Hashable {
    case term(GlossaryTerm)
    case category(GlossaryCategory)
    case allTerms
}

extension View {
    /// Registers the glossary screens. Apply once, at the root of each
    /// navigation stack that shows glossary links.
    func glossaryDestinations() -> some View {
        navigationDestination(for: GlossaryDestination.self) { destination in
            switch destination {
            case .term(let term):
                GlossaryTermView(term: term)
            case .category(let category):
                GlossaryCategoryView(category: category)
            case .allTerms:
                GlossaryAllTermsView()
            }
        }
    }
}
