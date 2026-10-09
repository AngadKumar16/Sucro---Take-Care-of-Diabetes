//
//  GlossaryCategoryView.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// All the terms in one topic.
struct GlossaryCategoryView: View {
    let category: GlossaryCategory

    var body: some View {
        List(Glossary.shared.terms(in: category)) { term in
            GlossaryTermRow(term: term)
        }
        .listStyle(.insetGrouped)
        .instrumentBackground()
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        GlossaryCategoryView(category: .insulin)
            .glossaryDestinations()
    }
    .environment(SettingsStore())
}
