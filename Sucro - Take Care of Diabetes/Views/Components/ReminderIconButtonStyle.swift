//
//  ReminderIconButtonStyle.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// Small tinted circle for the reminder card's icon buttons, with a full
/// 44pt tap area around it.
struct ReminderIconButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(tint)
            .frame(width: 32, height: 32)
            .background(tint.opacity(configuration.isPressed ? 0.25 : 0.1), in: .circle)
            .frame(width: 44, height: 44)
            .contentShape(.rect)
    }
}
