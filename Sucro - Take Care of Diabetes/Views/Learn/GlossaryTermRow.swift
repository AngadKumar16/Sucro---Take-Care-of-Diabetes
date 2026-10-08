//
//  GlossaryTermRow.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// A term's name with the first line of its definition.
struct GlossaryTermRow: View {
    let term: GlossaryTerm
    var showsCategory = false
    /// Name only, with the topic icon, for short lists like Start Here.
    var isCompact = false

    var body: some View {
        NavigationLink(value: GlossaryDestination.term(term)) {
            if isCompact {
                Label {
                    Text(term.name)
                } icon: {
                    GlossaryCategoryIcon(category: term.category)
                }
            } else {
                details
            }
        }
    }

    private var details: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(term.name)
                    .font(.body.weight(.medium))
                Text(GlossaryTerm.unbreakable(term.summary))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if showsCategory {
                    Label(term.category.title, systemImage: term.category.symbol)
                        .font(.caption)
                        .foregroundStyle(term.category.color)
                        .padding(.top, 2)
                }
            }
            .padding(.vertical, 2)
    }
}
