//
//  ReminderIconButtonStyle.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// A small printed square for the reminder card's icon buttons, with a
/// full 44pt tap area around it.
struct ReminderIconButtonStyle: ButtonStyle {
    let tint: Color
    var filled = false

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(filled ? Theme.card : tint)
            .frame(width: 34, height: 34)
            .background(filled ? tint : Theme.card)
            .overlay(Rectangle().strokeBorder(tint, lineWidth: 1.5))
            .background(Theme.ink.offset(x: pressed ? 0 : 2, y: pressed ? 0 : 2))
            .offset(x: pressed ? 2 : 0, y: pressed ? 2 : 0)
            .frame(width: 44, height: 44)
            .contentShape(.rect)
    }
}

