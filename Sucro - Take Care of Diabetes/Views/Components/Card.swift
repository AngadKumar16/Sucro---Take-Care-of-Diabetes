//
//  Card.swift
//  Sucro - Take Care of Diabetes
//
//  The panel used on Today and Trends: soft, rounded card stock with a
//  light edge and shadow, so screens feel friendly rather than machined.
//

import SwiftUI

struct CardBackground: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .softPanel(padding: padding)
    }
}

extension View {
    /// Rounded card stock with a hairline edge and a soft shadow. A colored
    /// edge marks a card that needs attention.
    func softPanel(padding: CGFloat = 16, border: Color = Theme.rule) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: .rect(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(border, lineWidth: 1))
            .shadow(color: Theme.ink.opacity(0.07), radius: 12, y: 4)
    }

    /// A small, friendly section label: sentence case, not shouted.
    func friendlyLabel() -> some View {
        self
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.soft)
    }
}

/// A soft, rounded filled button for the main action on a card.
struct SoftButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Theme.onAccent)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Theme.green, in: .rect(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
            .contentShape(.rect)
    }
}

extension ButtonStyle where Self == SoftButtonStyle {
    static var soft: SoftButtonStyle { SoftButtonStyle() }
}

extension View {
    func card(padding: CGFloat = 16) -> some View {
        modifier(CardBackground(padding: padding))
    }
}

/// A section title for card-based screens, with an optional trailing button.
struct CardHeader<Accessory: View>: View {
    let title: String
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            accessory
        }
    }
}

extension CardHeader where Accessory == EmptyView {
    init(_ title: String) {
        self.title = title
        self.accessory = EmptyView()
    }
}

extension CardHeader {
    init(_ title: String, @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.accessory = accessory()
    }
}
