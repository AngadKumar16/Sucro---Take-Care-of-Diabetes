//
//  InsulinPen.swift
//  Sucro - Take Care of Diabetes
//
//  A printed insulin pen whose dose window shows the units being logged,
//  so the screen reads like the pen in your hand.
//

import SwiftUI

struct InsulinPen: View {
    let units: Double

    var body: some View {
        Canvas { context, size in
            let s = size.width / 330
            func r(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> CGRect {
                CGRect(x: x * s, y: y * s, width: w * s, height: h * s)
            }
            let ink = GraphicsContext.Shading.color(Theme.ink)
            // Needle cap.
            context.stroke(Path(r(2, 28, 18, 12)), with: ink, lineWidth: 1.4)
            // Barrel, with a hatched shadow along the bottom.
            let barrel = Path(roundedRect: r(18, 14, 214, 40), cornerRadius: 14 * s)
            context.fill(barrel, with: .color(Theme.card))
            context.stroke(barrel.offsetBy(dx: 2, dy: 1.5), with: .color(Theme.vermilion.opacity(0.4)), lineWidth: 1.5)
            context.stroke(barrel, with: ink, lineWidth: 1.5)
            var hatch = Path()
            for x in stride(from: 30.0, through: 220, by: 5) {
                hatch.move(to: CGPoint(x: x * s, y: 50 * s))
                hatch.addLine(to: CGPoint(x: (x - 6) * s, y: 44 * s))
            }
            context.stroke(hatch, with: .color(Theme.ink.opacity(0.25)), lineWidth: 0.8)
            // Cartridge window with insulin left.
            context.stroke(Path(r(36, 25, 54, 17)), with: .color(Theme.green), lineWidth: 1.2)
            context.fill(Path(r(39, 28, 34, 11)), with: .color(Theme.green.opacity(0.35)))
            // Clip.
            context.stroke(Path(r(128, 8, 80, 7)), with: ink, lineWidth: 1.2)
            // Dose window.
            context.fill(Path(r(144, 21, 62, 26)), with: .color(Theme.card))
            context.stroke(Path(r(144, 21, 62, 26)), with: ink, lineWidth: 1.5)
            context.draw(Text(units.formatted(.number.precision(.fractionLength(1))))
                .font(.system(size: 19 * s, weight: .semibold, design: .serif).monospacedDigit())
                .foregroundStyle(Theme.ink), at: CGPoint(x: 175 * s, y: 34 * s))
            // Ridged dial.
            context.fill(Path(roundedRect: r(232, 10, 54, 48), cornerRadius: 8 * s), with: .color(Theme.green))
            var ridges = Path()
            for i in 0..<7 {
                let x = (240 + Double(i) * 6) * s
                ridges.move(to: CGPoint(x: x, y: 16 * s))
                ridges.addLine(to: CGPoint(x: x, y: 52 * s))
            }
            context.stroke(ridges, with: .color(Theme.card.opacity(0.6)), lineWidth: 1.4)
            // Button.
            context.stroke(Path(roundedRect: r(286, 20, 26, 28), cornerRadius: 6 * s), with: ink, lineWidth: 1.4)
        }
        .aspectRatio(330 / 70, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel("Insulin pen dialed to \(units.formatted(.number.precision(.fractionLength(1)))) units")
    }
}

#Preview {
    InsulinPen(units: 4.5)
        .padding()
        .background(Theme.paper)
}
