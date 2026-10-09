//
//  Theme.swift
//  Sucro - Take Care of Diabetes
//
//  The print look: card stock on grainy paper, printed in a few inks like
//  a two-color riso run. Green ink is in range and anything you can
//  operate; vermilion is lows, urgent highs and destructive actions; amber
//  is high. Text and rules are black ink.
//

import SwiftUI

nonisolated enum Theme {
    // MARK: Paper and inks

    /// The page every screen is printed on.
    static let paper = Color(light: UIColor(red: 0.937, green: 0.918, blue: 0.878, alpha: 1),
                             dark: UIColor(red: 0.090, green: 0.082, blue: 0.071, alpha: 1))

    /// Card stock: cards, rows and control surfaces.
    static let card = Color(light: UIColor(red: 0.973, green: 0.961, blue: 0.933, alpha: 1),
                            dark: UIColor(red: 0.130, green: 0.118, blue: 0.102, alpha: 1))

    /// Text, borders and rules.
    static let ink = Color(light: UIColor(red: 0.118, green: 0.110, blue: 0.094, alpha: 1),
                           dark: UIColor(red: 0.929, green: 0.902, blue: 0.847, alpha: 1))

    /// In range, primary actions, links.
    static let green = Color(light: UIColor(red: 0.122, green: 0.420, blue: 0.290, alpha: 1),
                             dark: UIColor(red: 0.424, green: 0.780, blue: 0.604, alpha: 1))

    /// Lows, urgent highs, destructive actions.
    static let vermilion = Color(light: UIColor(red: 0.851, green: 0.278, blue: 0.169, alpha: 1),
                                 dark: UIColor(red: 1.000, green: 0.478, blue: 0.361, alpha: 1))

    /// High but not urgent.
    static let amber = Color(light: UIColor(red: 0.710, green: 0.396, blue: 0.114, alpha: 1),
                             dark: UIColor(red: 0.878, green: 0.635, blue: 0.353, alpha: 1))

    /// Secondary text printed in a lighter impression.
    static let soft = Color(light: UIColor(red: 0.384, green: 0.357, blue: 0.310, alpha: 1),
                            dark: UIColor(red: 0.690, green: 0.659, blue: 0.604, alpha: 1))

    /// Hairline rules between rows.
    static let rule = Color(light: UIColor(white: 0, alpha: 0.16),
                            dark: UIColor(white: 1, alpha: 0.16))

    /// The second-ink offset behind cards, slightly out of register.
    static let offset = Color(light: UIColor(red: 0.122, green: 0.420, blue: 0.290, alpha: 0.55),
                              dark: UIColor(red: 0.424, green: 0.780, blue: 0.604, alpha: 0.35))

    // MARK: Older names, kept so existing screens pick up the new look

    static let body = paper
    static let panel = card
    static let seam = ink
    static let print = ink
    /// Text on a filled green button.
    static let onAccent = card
    static let indigo = Color(light: UIColor(red: 0.27, green: 0.25, blue: 0.70, alpha: 1),
                              dark: UIColor(red: 0.47, green: 0.45, blue: 0.95, alpha: 1))
    static let brandGradient = LinearGradient(colors: [green, green], startPoint: .top, endPoint: .bottom)

    static let cornerRadius: CGFloat = 0
    static let panelRadius: CGFloat = 0

    // MARK: Type

    /// Measured values: New York with even-width digits.
    static func readout(_ style: Font.TextStyle, weight: Font.Weight = .medium) -> Font {
        .system(style, design: .serif, weight: weight).monospacedDigit()
    }

    /// Small printed values: times, units, codes.
    static func mono(_ style: Font.TextStyle, weight: Font.Weight = .medium) -> Font {
        .system(style, design: .monospaced, weight: weight)
    }
}

extension Color {
    /// A color that switches with light and dark mode.
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

// MARK: - Surfaces

/// Paper grain: a fixed scatter of fine ink specks.
struct PaperGrain: View {
    var body: some View {
        Canvas { context, size in
            var generator = SplitMix(seed: 42)
            let count = Int(size.width * size.height / 90)
            for _ in 0..<count {
                let x = Double(generator.next() % 10_000) / 10_000 * size.width
                let y = Double(generator.next() % 10_000) / 10_000 * size.height
                let r = 0.35 + Double(generator.next() % 100) / 100 * 0.55
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(Theme.ink.opacity(0.10)))
            }
        }
        .drawingGroup()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private struct SplitMix {
        var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }
}

extension View {
    /// Puts a screen on grainy paper. Lists and forms drop their own
    /// background so the paper shows around their rows.
    func instrumentBackground() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background {
                ZStack {
                    Theme.paper
                    PaperGrain()
                }
                .ignoresSafeArea()
            }
    }

    /// Small, tracked, uppercase text, like a printed label.
    func instrumentLabel() -> some View {
        self
            .font(.caption2.weight(.semibold).monospaced())
            .textCase(.uppercase)
            .tracking(1.1)
            .foregroundStyle(Theme.soft)
    }

    /// Card stock, a black rule and the green offset, around content that
    /// already has its own padding.
    func printSurface() -> some View {
        self
            .background(Theme.card)
            .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: 1.5))
            .background(Theme.offset.offset(x: 3, y: 3))
    }

    /// A card: card stock, a black rule, and a green second-ink offset.
    func instrumentPanel(padding: CGFloat = 16, border: Color = Theme.ink, offset: Color = Theme.offset) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .overlay(Rectangle().strokeBorder(border, lineWidth: 1.5))
            .background(offset.offset(x: 3, y: 3))
    }
}

// MARK: - Buttons

/// A printed button: a solid or outlined block with a black offset that
/// disappears as the button sinks under your finger.
struct PrintButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, destructive }
    var kind: Kind = .primary
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        PrintButtonBody(configuration: configuration, kind: kind, compact: compact)
    }
}

private struct PrintButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let kind: PrintButtonStyle.Kind
    let compact: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let pressed = configuration.isPressed
        let colors: (fill: Color, text: Color, border: Color) = switch kind {
        case .primary: (Theme.green, Theme.card, Theme.green)
        case .secondary: (Theme.card, Theme.ink, Theme.ink)
        case .destructive: (Theme.vermilion, Theme.card, Theme.vermilion)
        }
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(colors.text)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: compact ? 44 : 50)
            .background(colors.fill)
            .overlay(Rectangle().strokeBorder(colors.border, lineWidth: 1.5))
            .background(Theme.ink.offset(x: pressed ? 0 : 2, y: pressed ? 0 : 2))
            .offset(x: pressed && !reduceMotion ? 2 : 0, y: pressed && !reduceMotion ? 2 : 0)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(.snappy(duration: 0.12), value: pressed)
            .contentShape(.rect)
    }
}

extension ButtonStyle where Self == PrintButtonStyle {
    static var printPrimary: PrintButtonStyle { PrintButtonStyle(kind: .primary) }
    static var printSecondary: PrintButtonStyle { PrintButtonStyle(kind: .secondary) }
    static var printDestructive: PrintButtonStyle { PrintButtonStyle(kind: .destructive) }
}

// MARK: - Zones

extension GlucoseZone {
    /// All five zones, highest first, the way charts stack them.
    static let topDown: [GlucoseZone] = [.urgentHigh, .high, .inRange, .low, .urgentLow]

    /// Neighboring zones drawn side by side need telling apart, so the
    /// milder low is a lighter impression of the same ink.
    var bandColor: Color {
        switch self {
        case .low: return color.opacity(0.6)
        default: return color
        }
    }

    var symbol: String {
        switch self {
        case .urgentHigh: return "arrow.up.to.line"
        case .high: return "arrow.up"
        case .inRange: return "checkmark"
        case .low: return "arrow.down"
        case .urgentLow: return "arrow.down.to.line"
        }
    }
}
