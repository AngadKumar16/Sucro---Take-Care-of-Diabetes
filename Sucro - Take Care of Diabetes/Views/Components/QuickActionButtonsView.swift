//
//  QuickActionButtonsView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//
//  Three soft keys, each drawn as the thing it logs: a kitchen scale
//  weighing today's carbs, an insulin pen dialed to today's total, and a
//  body with the next site marked.
//

import SwiftUI

struct QuickActionButtonsView: View {
    let onLogMeal: () -> Void
    let onQuickBolus: () -> Void
    let onChangeSite: () -> Void
    var onLogPreset: ((MealTemplate) -> Void)? = nil
    var todayCarbs: Double = 0
    var todayInsulin: Double = 0
    var nextSite: SiteLocation? = nil

    @State private var loggedPreset = 0
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            // Tap opens the carb form; touch and hold shows saved meals.
            Menu {
                Section("Log a Saved Meal") {
                    ForEach(MealTemplate.standardPresets) { preset in
                        Button("\(preset.name) (\(Int(preset.carbs))g carbs)") {
                            onLogPreset?(preset)
                            loggedPreset += 1
                        }
                    }
                }
            } label: {
                QuickActionLabel(title: "Log Meal", shown: "Meal", tint: Theme.amber, detail: "\(Int(todayCarbs)) g today") {
                    MiniScale(load: todayCarbs / 150)
                }
            } primaryAction: {
                onLogMeal()
            }
            .menuStyle(.button)
            .buttonStyle(QuickActionButtonStyle())
            .accessibilityLabel("Log Meal")
            .accessibilityHint("Touch and hold for saved meals")

            Button(action: onQuickBolus) {
                QuickActionLabel(title: "Quick Bolus", shown: "Insulin", tint: Theme.green, detail: "\(todayInsulin.formatted(.number.precision(.fractionLength(0...1)))) U today") {
                    InsulinPen(units: todayInsulin)
                        .frame(width: 92)
                        .rotationEffect(.degrees(-28))
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(QuickActionButtonStyle())

            Button(action: onChangeSite) {
                QuickActionLabel(title: "Change Site", shown: "Site", tint: Theme.vermilion, detail: nextSite.map { "Next: \($0.shortName)" } ?? " ") {
                    MiniBody(site: nextSite)
                }
            }
            .buttonStyle(QuickActionButtonStyle())
        }
        .sensoryFeedback(.success, trigger: loggedPreset)
    }
}

private struct QuickActionLabel<Art: View>: View {
    /// The button's name for VoiceOver and UI tests.
    let title: String
    /// The short word printed on the key.
    let shown: String
    let tint: Color
    let detail: String
    @ViewBuilder var art: Art

    var body: some View {
        VStack(spacing: 6) {
            art
                .frame(height: 58)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(tint.opacity(0.12), in: .rect(cornerRadius: 14, style: .continuous))
                .accessibilityHidden(true)
            Text(shown)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(detail)
                .font(.caption)
                .foregroundStyle(Theme.soft)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 112)
        .padding(8)
        // The name stays "Quick Bolus"; today's figure is read as its value.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(detail)
    }
}

/// A small kitchen scale; the needle swings with how much has been eaten.
private struct MiniScale: View {
    /// 0 to 1 across the dial.
    let load: Double

    var body: some View {
        Canvas { context, size in
            let ink = GraphicsContext.Shading.color(Theme.ink)
            let w = size.width, h = size.height
            let cx = w / 2
            // Bowl.
            var bowl = Path()
            bowl.move(to: CGPoint(x: cx - 22, y: 6))
            bowl.addQuadCurve(to: CGPoint(x: cx + 22, y: 6), control: CGPoint(x: cx, y: 26))
            bowl.closeSubpath()
            context.fill(bowl, with: .color(Theme.green.opacity(0.3)))
            context.stroke(bowl, with: ink, lineWidth: 1.4)
            // Platform and stem.
            context.stroke(Path(CGRect(x: cx - 26, y: 17, width: 52, height: 3)), with: ink, lineWidth: 1.4)
            context.stroke(Path(CGRect(x: cx - 3, y: 20, width: 6, height: 5)), with: ink, lineWidth: 1.2)
            // Body.
            let body = Path(roundedRect: CGRect(x: cx - 26, y: 25, width: 52, height: h - 26), cornerRadius: 6)
            context.fill(body, with: .color(Theme.card))
            context.stroke(body, with: ink, lineWidth: 1.4)
            // Dial and needle.
            let center = CGPoint(x: cx, y: 25 + (h - 26) / 2)
            let dial = Path(ellipseIn: CGRect(x: center.x - 13, y: center.y - 13, width: 26, height: 26))
            context.stroke(dial, with: ink, lineWidth: 1.2)
            let angle = Angle.degrees(-210 + 240 * min(max(load, 0), 1)).radians
            var needle = Path()
            needle.move(to: center)
            needle.addLine(to: CGPoint(x: center.x + 10 * cos(angle), y: center.y + 10 * sin(angle)))
            context.stroke(needle, with: .color(Theme.vermilion), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }
        .frame(width: 60)
    }
}

/// A small body outline with the next site marked in green.
private struct MiniBody: View {
    let site: SiteLocation?

    var body: some View {
        let side = BodySide.showing(site)
        GeometryReader { proxy in
            let size = proxy.size
            ZStack(alignment: .topLeading) {
                BodyOutline()
                    .fill(Theme.card)
                BodyOutline()
                    .stroke(Theme.ink, lineWidth: 1.2)
                if let point = site?.point(on: side) {
                    Circle()
                        .fill(Theme.green)
                        .overlay(Circle().strokeBorder(Theme.card, lineWidth: 1))
                        .frame(width: 9, height: 9)
                        .position(x: point.x / 100 * size.width, y: point.y / 290 * size.height)
                }
            }
        }
        .aspectRatio(100 / 290, contentMode: .fit)
    }
}

private extension SiteLocation {
    /// Fits under a tile: "L thigh".
    var shortName: String {
        spokenName
            .replacingOccurrences(of: "Left ", with: "L ")
            .replacingOccurrences(of: "Right ", with: "R ")
            .replacingOccurrences(of: "Center ", with: "C ")
    }
}

/// A soft key: rounded card stock that dips slightly under your finger.
struct QuickActionButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .foregroundStyle(Theme.ink)
            .background(Theme.card, in: .rect(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.rule, lineWidth: 1))
            .shadow(color: Theme.ink.opacity(pressed ? 0.03 : 0.07), radius: pressed ? 4 : 10, y: pressed ? 1 : 4)
            .scaleEffect(pressed && !reduceMotion ? 0.96 : 1)
            .animation(.snappy(duration: 0.15), value: pressed)
            .contentShape(.rect)
            .sensoryFeedback(.impact(weight: .light), trigger: pressed) { _, new in new }
    }
}

#Preview {
    QuickActionButtonsView(onLogMeal: {}, onQuickBolus: {}, onChangeSite: {}, onLogPreset: { _ in },
                           todayCarbs: 45, todayInsulin: 6, nextSite: .thighLeft)
        .padding()
        .instrumentBackground()
}
