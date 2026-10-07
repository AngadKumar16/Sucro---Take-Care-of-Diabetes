//
//  MoreButton.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// Adds the "More" button that opens Insights, Reports, Devices, Settings
/// and Help to a main tab's navigation bar.
struct MoreButton: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("More", systemImage: "ellipsis.circle", action: action)
                    .accessibilityIdentifier("moreButton")
            }
        }
    }
}

extension View {
    func moreButton(action: @escaping () -> Void) -> some View {
        modifier(MoreButton(action: action))
    }
}
