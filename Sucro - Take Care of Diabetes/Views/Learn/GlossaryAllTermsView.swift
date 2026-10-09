//
//  GlossaryAllTermsView.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// Every term, A–Z, with a letter index down the side.
struct GlossaryAllTermsView: View {
    private let groups = Glossary.shared.alphabetical

    var body: some View {
        List {
            ForEach(groups, id: \.letter) { group in
                Section(group.letter) {
                    ForEach(group.terms) { term in
                        GlossaryTermRow(term: term)
                    }
                }
                .listRowBackground(Theme.card)
                .sectionIndexLabel(group.letter)
            }
        }
        .listStyle(.plain)
        .listSectionIndexVisibility(.visible)
        .navigationTitle("All Terms")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        GlossaryAllTermsView()
            .glossaryDestinations()
    }
    .environment(SettingsStore())
}
