//
//  GlossaryTermSheet.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// A glossary term opened from elsewhere in the app, in its own sheet so
/// related terms can be followed without leaving the current screen.
struct GlossaryTermSheet: View {
    @Environment(\.dismiss) private var dismiss
    let term: GlossaryTerm

    var body: some View {
        NavigationStack {
            GlossaryTermView(term: term)
                .glossaryDestinations()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }
}
