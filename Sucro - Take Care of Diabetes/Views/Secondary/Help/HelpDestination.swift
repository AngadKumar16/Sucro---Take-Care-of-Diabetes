//
//  HelpDestination.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// Screens reachable from Settings and Help.
enum HelpDestination: Hashable {
    case devices
    case help
    case article(HelpArticle)
    case safety
}

extension View {
    /// Registers the screens Help links to. Apply once, at the root of the
    /// navigation stack, so links work however deep Help is pushed.
    func helpDestinations() -> some View {
        navigationDestination(for: HelpDestination.self) { destination in
            switch destination {
            case .devices:
                DevicesView()
            case .help:
                HelpView()
            case .article(let article):
                FAQDetailView(article: article)
            case .safety:
                SafetyInfoView()
            }
        }
    }
}
