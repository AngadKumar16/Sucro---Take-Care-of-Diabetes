//
//  Guide.swift
//  Sucro - Take Care of Diabetes
//
//  Illustrated explainers that go deeper than a glossary term, shown from
//  Settings › Glucose and the Learn tab.
//

import SwiftUI

enum Guide: String, CaseIterable, Identifiable, Hashable {
    case ranges
    case timeInRange
    case units
    case treatingLows

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ranges: return "Glucose Ranges"
        case .timeInRange: return "Time in Range"
        case .units: return "mg/dL and mmol/L"
        case .treatingLows: return "Treating a Low"
        }
    }

    var subtitle: String {
        switch self {
        case .ranges: return "What each line means and what to do"
        case .timeInRange: return "The daily goal many people aim for"
        case .units: return "Two units, one number"
        case .treatingLows: return "The rule of 15, step by step"
        }
    }

    var symbol: String {
        switch self {
        case .ranges: return "ruler.fill"
        case .timeInRange: return "chart.bar.fill"
        case .units: return "arrow.left.arrow.right"
        case .treatingLows: return "cube.fill"
        }
    }

    var colors: [Color] {
        switch self {
        case .ranges: return [.accentColor, .green]
        case .timeInRange: return [Theme.indigo, .accentColor]
        case .units: return [.blue, .purple]
        case .treatingLows: return [.orange, .red]
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    @MainActor @ViewBuilder
    var content: some View {
        switch self {
        case .ranges: RangesGuideView()
        case .timeInRange: TimeInRangeGuideView()
        case .units: UnitsGuideView()
        case .treatingLows: TreatingLowsGuideView()
        }
    }
}

extension View {
    /// Registers guide pages. Apply at the root of a navigation stack that
    /// shows `NavigationLink(value: Guide)`.
    func guideDestinations() -> some View {
        navigationDestination(for: Guide.self) { $0.content }
    }
}
