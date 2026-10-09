//
//  QuickActionButtonsView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI

struct QuickActionButtonsView: View {
    let onLogMeal: () -> Void
    let onQuickBolus: () -> Void
    let onChangeSite: () -> Void
    var onLogPreset: ((MealTemplate) -> Void)? = nil

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
                QuickActionLabel(title: "Log Meal", icon: "fork.knife")
            } primaryAction: {
                onLogMeal()
            }
            .menuStyle(.button)
            .buttonStyle(QuickActionButtonStyle())
            .accessibilityLabel("Log Meal")
            .accessibilityHint("Touch and hold for saved meals")

            Button(action: onQuickBolus) {
                QuickActionLabel(title: "Quick Bolus", icon: "syringe")
            }
            .buttonStyle(QuickActionButtonStyle())

            Button(action: onChangeSite) {
                QuickActionLabel(title: "Change Site", icon: "bandage")
            }
            .buttonStyle(QuickActionButtonStyle())
        }
        .sensoryFeedback(.success, trigger: loggedPreset)
    }
}

private struct QuickActionLabel: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2.weight(.medium))
                .foregroundStyle(Theme.green)
                .accessibilityHidden(true)
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .tracking(0.8)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .padding(.vertical, 8)
    }
}

/// A printed key: card stock, a black rule and a black offset that the
/// key sinks into while pressed. Neutral on purpose; the inks mean zones.
struct QuickActionButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .foregroundStyle(Theme.ink)
            .background(Theme.card)
            .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: 1.5))
            .background(Theme.ink.offset(x: pressed ? 0 : 2, y: pressed ? 0 : 2))
            .offset(x: pressed && !reduceMotion ? 2 : 0, y: pressed && !reduceMotion ? 2 : 0)
            .animation(.snappy(duration: 0.12), value: pressed)
            .contentShape(.rect)
            .sensoryFeedback(.impact(weight: .light), trigger: pressed) { _, new in new }
    }
}

#Preview {
    QuickActionButtonsView(onLogMeal: {}, onQuickBolus: {}, onChangeSite: {}, onLogPreset: { _ in })
        .padding()
        .background(Color(.systemGroupedBackground))
}
