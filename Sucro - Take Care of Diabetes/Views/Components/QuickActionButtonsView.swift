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

    var body: some View {
        HStack(spacing: 16) {
            // Log Meal Button — long-press for quick presets.
            QuickActionButton(
                title: "Log Meal",
                icon: "camera.fill",
                color: .blue,
                action: onLogMeal,
                presets: MealTemplate.standardPresets,
                onPreset: onLogPreset
            )

            // Quick Bolus Button
            QuickActionButton(
                title: "Quick Bolus",
                icon: "syringe.fill",
                color: .green,
                action: onQuickBolus
            )

            // Change Site Button
            QuickActionButton(
                title: "Change Site",
                icon: "figure.walk",
                color: .purple,
                action: onChangeSite
            )
        }
        .padding(.horizontal, 16)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    var presets: [MealTemplate] = []
    var onPreset: ((MealTemplate) -> Void)? = nil

    @State private var isPressed = false
    @State private var showingPresets = false

    private var supportsPresets: Bool { !presets.isEmpty && onPreset != nil }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        // simultaneousGesture fires reliably alongside the Button's tap; a plain
        // .onLongPressGesture perform is swallowed by the Button.
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onChanged { _ in
                    guard supportsPresets else { return }
                    withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
                    guard supportsPresets else { return }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showingPresets = true
                }
        )
        .alert("Quick Presets", isPresented: $showingPresets) {
            ForEach(presets) { preset in
                Button("\(preset.name) (\(Int(preset.carbs))g carbs)") {
                    onPreset?(preset)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Log a preset meal instantly")
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        QuickActionButtonsView(
            onLogMeal: {},
            onQuickBolus: {},
            onChangeSite: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
