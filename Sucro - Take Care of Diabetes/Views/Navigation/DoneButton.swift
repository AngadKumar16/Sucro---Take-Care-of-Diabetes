//
//  DoneButton.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// Adds a Done button that dismisses the sheet the view is presented in.
struct DoneButton: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: close)
            }
        }
    }

    private func close() {
        dismiss()
    }
}

extension View {
    func doneButton() -> some View {
        modifier(DoneButton())
    }
}
