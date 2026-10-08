//
//  Appearance.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// The app's light/dark setting. `.system` follows the phone.
nonisolated enum Appearance: String, CaseIterable, Sendable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
