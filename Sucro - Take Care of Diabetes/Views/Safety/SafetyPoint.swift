//
//  SafetyPoint.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// One line of the safety notice, printed like a numbered clause: a green
/// mono number, the sentence, and a dotted rule underneath.
struct SafetyPoint: View {
    let number: Int
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(number, format: .number.precision(.integerLength(2)))
                .font(Theme.mono(.subheadline, weight: .semibold))
                .foregroundStyle(Theme.green)
                .accessibilityHidden(true)
            Text(text)
                .font(.body)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Theme.soft)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Line()
                .stroke(Theme.rule, style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                .frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { $0.move(to: CGPoint(x: rect.minX, y: rect.midY)); $0.addLine(to: CGPoint(x: rect.maxX, y: rect.midY)) }
        }
    }
}

/// The emergency line, set apart in vermilion so it can be found at a glance.
struct SafetyEmergencyPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: "phone.fill")
                .foregroundStyle(Theme.vermilion)
                .accessibilityHidden(true)
            Text(text)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .instrumentPanel(padding: 14, border: Theme.vermilion, offset: Theme.vermilion.opacity(0.35))
        .accessibilityElement(children: .combine)
    }
}
