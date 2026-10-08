//
//  GlossaryLink.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// A small "learn more" button that opens a glossary term in a sheet.
struct GlossaryLink: View {
    let termID: String
    /// Defaults to "What is <term>?".
    var title: String?

    @State private var presentedTerm: GlossaryTerm?

    var body: some View {
        if let term = Glossary.shared.term(termID) {
            Button(title ?? "What is \(term.name.lowercased())?", systemImage: "book") {
                presentedTerm = term
            }
            .font(.footnote)
            .sheet(item: $presentedTerm, content: GlossaryTermSheet.init)
        }
    }
}
