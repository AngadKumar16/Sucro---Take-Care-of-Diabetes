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
    
    var body: some View {
        HStack(spacing: 16) {
            // Log Meal Button
            QuickActionButton(
                title: "Log Meal",
                icon: "camera.fill",
                color: .blue,
                action: onLogMeal
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
    
    @State private var isPressed = false
    @State private var showingPresets = false
    
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
        .onLongPressGesture(
            minimumDuration: 0.5,
            maximumDistance: 10,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                // Show presets (could be expanded with actual preset UI)
                showingPresets = true
            }
        )
        .alert("Quick Presets", isPresented: $showingPresets) {
            Button("Breakfast (40g carbs)") {
                // Handle breakfast preset
            }
            Button("Lunch (60g carbs)") {
                // Handle lunch preset
            }
            Button("Dinner (70g carbs)") {
                // Handle dinner preset
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Select a preset meal option")
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
