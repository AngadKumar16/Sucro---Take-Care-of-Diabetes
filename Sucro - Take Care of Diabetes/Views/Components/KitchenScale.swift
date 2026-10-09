//
//  KitchenScale.swift
//  Sucro - Take Care of Diabetes
//
//  Carbs on a kitchen scale: drag around the dial to weigh, or tap the
//  steps. The dial reads 0–120 g; heavier meals are typed in the field.
//

import SwiftUI

struct KitchenScale: View {
    @Binding var grams: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let dialMax = 120.0
    /// The dial sweeps 140° from lower left to lower right, over the top.
    private static let startAngle = 200.0
    private static let sweep = 140.0

    var body: some View {
        GeometryReader { proxy in
            dial(size: proxy.size)
        }
        .frame(height: 230)
        .sensoryFeedback(trigger: grams, feedback)
        .accessibilityElement()
        .accessibilityLabel("Carbs scale")
        .accessibilityValue("\(Int(grams)) grams")
        .accessibilityAdjustableAction(adjust)
    }

    private func dial(size: CGSize) -> some View {
        let center = CGPoint(x: size.width / 2, y: size.height * 0.64)
        let radius: CGFloat = min(size.width * 0.27, size.height * 0.33)
        return ZStack {
            Canvas { context, canvasSize in
                draw(in: &context, size: canvasSize, center: center, radius: radius)
            }
            readout
                .position(x: center.x, y: center.y + radius * 0.5)
        }
        .contentShape(.rect)
        .gesture(DragGesture(minimumDistance: 0).onChanged { value in weigh(at: value.location, center: center) })
    }

    private var readout: some View {
        VStack(spacing: 0) {
            Text("\(grams.formatted(.number.precision(.fractionLength(0)))) g")
                .font(.system(size: 28, weight: .semibold, design: .serif).monospacedDigit())
                .contentTransition(.numericText(value: grams))
            Text("CARBS")
                .font(Theme.mono(.caption2))
                .foregroundStyle(Theme.soft)
        }
    }

    /// A light click every 5 g and a firmer one every 15 g.
    private func feedback(_ old: Double, _ new: Double) -> SensoryFeedback? {
        if new.truncatingRemainder(dividingBy: 15) == 0 { return .impact(weight: .medium) }
        if new.truncatingRemainder(dividingBy: 5) == 0 { return .selection }
        return nil
    }

    private func adjust(_ direction: AccessibilityAdjustmentDirection) {
        switch direction {
        case .increment: grams = min(grams + 5, 500)
        case .decrement: grams = max(grams - 5, 0)
        @unknown default: break
        }
    }

    private func polar(_ center: CGPoint, _ radius: CGFloat, _ angle: Double) -> CGPoint {
        CGPoint(x: center.x + radius * CGFloat(Foundation.cos(angle)), y: center.y + radius * CGFloat(Foundation.sin(angle)))
    }

    /// Turns a touch anywhere on the scale into grams along the dial.
    private func weigh(at location: CGPoint, center: CGPoint) {
        let dx = Double(location.x - center.x), dy = Double(location.y - center.y)
        var angle = atan2(dy, dx) * 180 / .pi
        if angle < 0 { angle += 360 }
        // Map 200°…340° onto the dial; outside snaps to the nearest end.
        let fraction = min(max((angle - Self.startAngle) / Self.sweep, 0), 1)
        let newValue = (fraction * Self.dialMax).rounded()
        if newValue != grams {
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.15)) { grams = newValue }
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, center: CGPoint, radius: CGFloat) {
        let w = size.width
        // Plate on the platform.
        let plate = Path(ellipseIn: CGRect(x: w * 0.14, y: 8, width: w * 0.72, height: 36))
        context.stroke(plate.offsetBy(dx: 2, dy: 1.5), with: .color(Theme.vermilion.opacity(0.4)), lineWidth: 2)
        context.fill(plate, with: .color(Theme.card))
        context.stroke(plate, with: .color(Theme.ink), lineWidth: 2)
        context.stroke(Path(ellipseIn: CGRect(x: w * 0.24, y: 14, width: w * 0.52, height: 22)), with: .color(Theme.ink.opacity(0.5)), lineWidth: 1)
        // Food grows with the weight.
        let food = min(grams / Self.dialMax, 1)
        if food > 0 {
            let fw = w * 0.42 * (0.4 + 0.6 * food)
            context.fill(Path(ellipseIn: CGRect(x: w / 2 - fw / 2, y: 18, width: fw, height: 14)), with: .color(Theme.amber.opacity(0.55)))
            context.fill(Path(ellipseIn: CGRect(x: w / 2 + fw * 0.18, y: 16, width: 9, height: 9)), with: .color(Theme.vermilion))
        }
        // Platform and body.
        context.fill(Path(CGRect(x: w * 0.1, y: 48, width: w * 0.8, height: 7)), with: .color(Theme.ink))
        var body = Path()
        body.move(to: CGPoint(x: w * 0.1, y: 55))
        body.addLine(to: CGPoint(x: w * 0.9, y: 55))
        body.addLine(to: CGPoint(x: w * 0.96, y: size.height - 4))
        body.addLine(to: CGPoint(x: w * 0.04, y: size.height - 4))
        body.closeSubpath()
        context.fill(body, with: .color(Theme.card))
        context.stroke(body, with: .color(Theme.ink), lineWidth: 2)
        // Dial face.
        let face = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        context.fill(face, with: .color(Theme.card))
        context.stroke(face, with: .color(Theme.ink), lineWidth: 2)
        context.stroke(Path(ellipseIn: CGRect(x: center.x - radius + 6, y: center.y - radius + 6, width: radius * 2 - 12, height: radius * 2 - 12)),
                       with: .color(Theme.ink.opacity(0.6)), lineWidth: 0.8)
        for g in stride(from: 0.0, through: Self.dialMax, by: 5) {
            let a = (Self.startAngle + g / Self.dialMax * Self.sweep) * .pi / 180
            let major = g.truncatingRemainder(dividingBy: 15) == 0
            let r1 = radius - 7, r2 = radius - (major ? 18 : 12)
            var tick = Path()
            tick.move(to: polar(center, r1, a))
            tick.addLine(to: polar(center, r2, a))
            context.stroke(tick, with: .color(Theme.ink), lineWidth: major ? 1.6 : 0.9)
            if g.truncatingRemainder(dividingBy: 30) == 0 {
                let rt = radius - 28
                context.draw(Text("\(Int(g))").font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.ink),
                             at: polar(center, rt, a))
            }
        }
        // Needle.
        let a = (Self.startAngle + min(grams, Self.dialMax) / Self.dialMax * Self.sweep) * .pi / 180
        var needle = Path()
        needle.move(to: center)
        needle.addLine(to: polar(center, (radius - 12), a))
        context.stroke(needle, with: .color(Theme.vermilion), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        context.fill(Path(ellipseIn: CGRect(x: center.x - 6, y: center.y - 6, width: 12, height: 12)), with: .color(Theme.vermilion))
    }
}

/// The scale with its quick steps and your usual meals, for the carbs form.
struct KitchenScaleSection: View {
    @Binding var gramsText: String
    @Binding var mealType: MealType
    @Binding var foodItems: String

    private var grams: Binding<Double> {
        Binding {
            parseNumber(gramsText) ?? 0
        } set: { newValue in
            gramsText = newValue > 0 ? editableNumber(newValue) : ""
        }
    }

    var body: some View {
        Section {
            KitchenScale(grams: grams)
            HStack(spacing: 8) {
                ForEach([-5.0, 5, 15, 30], id: \.self) { step in
                    Button(step > 0 ? "+\(Int(step))" : "−\(Int(-step))") {
                        grams.wrappedValue = min(max(grams.wrappedValue + step, 0), 500)
                    }
                    .buttonStyle(PrintButtonStyle(kind: .secondary, compact: true))
                    .accessibilityLabel(step > 0 ? "Add \(Int(step)) grams" : "Remove \(Int(-step)) grams")
                }
            }
            .listRowSeparator(.hidden)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(MealTemplate.standardPresets) { preset in
                        Button("\(preset.name) \(Int(preset.carbs)) g") {
                            grams.wrappedValue = preset.carbs
                            if let meal = MealType(stored: preset.name) { mealType = meal }
                            if foodItems.isEmpty { foodItems = preset.name }
                        }
                        .buttonStyle(PrintButtonStyle(kind: .secondary, compact: true))
                        .fixedSize()
                    }
                }
                .padding(.vertical, 4)
                .padding(.trailing, 4)
            }
            .scrollIndicators(.hidden)
        } header: {
            Text("Weigh it")
        } footer: {
            Text("Drag around the dial or tap a step. Your usual meals load their carbs in one tap.")
        }
        .listRowBackground(Theme.card)
    }
}
