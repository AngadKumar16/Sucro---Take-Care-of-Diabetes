//
//  GlossaryDisclaimer.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// The note under glossary content that it isn't personal medical advice.
struct GlossaryDisclaimer: View {
    var body: some View {
        Text("General information to help you understand diabetes terms. It isn't medical advice. Ask your care team what applies to you.")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}
