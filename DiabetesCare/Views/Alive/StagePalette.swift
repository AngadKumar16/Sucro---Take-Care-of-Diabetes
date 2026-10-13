//
//  StagePalette.swift
//  DiabetesCare
//
//  Each stage gets its own feel within the green family: brighter and
//  playful for a kid, fresh for a teen, calm for an adult. The accent
//  tints system controls; the wash is a faint color over the paper.
//

import SwiftUI

extension CareStage {
    var accent: Color {
        switch self {
        case .kid: Color(light: UIColor(red: 0.16, green: 0.58, blue: 0.33, alpha: 1),
                         dark: UIColor(red: 0.47, green: 0.86, blue: 0.56, alpha: 1))
        case .teen: Color(light: UIColor(red: 0.07, green: 0.50, blue: 0.47, alpha: 1),
                          dark: UIColor(red: 0.38, green: 0.82, blue: 0.76, alpha: 1))
        case .adult: Theme.green
        }
    }

    /// A barely-there color over the paper. Adults get none.
    var wash: Color {
        switch self {
        case .kid: Color(light: UIColor(red: 1.0, green: 0.84, blue: 0.40, alpha: 0.10),
                         dark: UIColor(red: 1.0, green: 0.84, blue: 0.40, alpha: 0.04))
        case .teen: Color(light: UIColor(red: 0.30, green: 0.75, blue: 0.80, alpha: 0.07),
                          dark: UIColor(red: 0.30, green: 0.75, blue: 0.80, alpha: 0.04))
        case .adult: .clear
        }
    }
}

extension EnvironmentValues {
    /// The current stage's wash, drawn by `instrumentBackground()`.
    @Entry var stageWash: Color = .clear
}

extension View {
    /// Applies the stage's accent and wash below this view.
    func stagePalette(_ stage: CareStage) -> some View {
        self
            .tint(stage.accent)
            .environment(\.stageWash, stage.wash)
    }
}
