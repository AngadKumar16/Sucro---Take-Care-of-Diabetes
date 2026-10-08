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
            .buttonStyle(QuickActionButtonStyle(color: .orange))
            .accessibilityLabel("Log Meal")
            .accessibilityHint("Touch and hold for saved meals")

            Button(action: onQuickBolus) {
                QuickActionLabel(title: "Quick Bolus", icon: "syringe")
            }
            .buttonStyle(QuickActionButtonStyle(color: .green))

            Button(action: onChangeSite) {
                QuickActionLabel(title: "Change Site", icon: "bandage")
            }
            .buttonStyle(QuickActionButtonStyle(color: .purple))
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
                .accessibilityHidden(true)
            Text(title)
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .padding(.vertical, 8)
    }
}

/// A filled tile that dims and shrinks a little while pressed.
struct QuickActionButtonStyle: ButtonStyle {
    let color: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(color.gradient, in: .rect(cornerRadius: 16))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
            .contentShape(.rect(cornerRadius: 16))
    }
}

#Preview {
    QuickActionButtonsView(onLogMeal: {}, onQuickBolus: {}, onChangeSite: {}, onLogPreset: { _ in })
        .padding()
        .background(Color(.systemGroupedBackground))
}
