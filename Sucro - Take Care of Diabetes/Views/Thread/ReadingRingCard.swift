//
//  ReadingRingCard.swift
//  Sucro - Take Care of Diabetes
//
//  The latest reading, set inside the glucose molecule: the thing being
//  measured. The ring is printed in black with a vermilion offset, the
//  ring oxygen marked, and the hydroxyl groups around it.
//

import SwiftUI

struct ReadingRingCard: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    /// Observed so an edit to this reading redraws it.
    @ObservedObject var reading: GlucoseReading
    let insulinOnBoard: Double
    let now: Date

    /// After this long the value is greyed out, since it may not reflect
    /// current glucose.
    private static let staleAfter: TimeInterval = 15 * 60

    private var isStale: Bool {
        guard let timestamp = reading.timestamp else { return true }
        return now.timeIntervalSince(timestamp) > Self.staleAfter
    }

    private var zone: GlucoseZone { settings.zone(for: reading.value) }
    private var trend: GlucoseTrend? { isStale ? nil : GlucoseTrend(stored: reading.trend) }
    private var inkColor: Color { isStale ? Theme.soft : zone.color }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ZStack {
                MoleculeRing()
                    .frame(width: 200, height: 210)
                VStack(spacing: 0) {
                    Text(settings.glucoseValueString(reading.value))
                        .font(.system(size: 56, weight: .semibold, design: .serif).monospacedDigit())
                        .foregroundStyle(inkColor)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .contentTransition(.numericText(value: reading.value))
                    Text(settings.glucoseUnit)
                        .font(Theme.mono(.caption))
                        .foregroundStyle(Theme.soft)
                }
                .frame(width: 120)
                .offset(y: 8)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text(isStale ? "Last reading" : zone.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.card)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(inkColor)
                if let trend {
                    Label {
                        Text(trend.description)
                            .font(.subheadline.weight(.semibold))
                    } icon: {
                        Image(systemName: trend.arrowSymbol)
                            .foregroundStyle(inkColor)
                    }
                    .foregroundStyle(Theme.ink)
                }
                if let timestamp = reading.timestamp {
                    Text(age(of: timestamp))
                        .font(.subheadline)
                        .foregroundStyle(isStale ? Theme.amber : Theme.soft)
                }
                Rectangle().fill(Theme.rule).frame(height: 1)
                InsulinOnBoardLabel(units: insulinOnBoard)
            }
            .padding(.top, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(readingDescription)
    }

    private var readingDescription: String {
        var parts = [settings.formattedGlucose(reading.value)]
        if !isStale || differentiateWithoutColor { parts.append(zone.name) }
        if let trend { parts.append(trend.description) }
        if let timestamp = reading.timestamp { parts.append(age(of: timestamp)) }
        return parts.joined(separator: ", ")
    }

    private func age(of timestamp: Date) -> String {
        if now.timeIntervalSince(timestamp) < 60 { return "Just now" }
        return timestamp.formatted(.relative(presentation: .named, unitsStyle: .abbreviated))
    }
}

/// β-D-glucopyranose drawn as a printed diagram: a hexagonal ring with the
/// ring oxygen at the top right, OH groups on four carbons and the CH₂OH arm.
struct MoleculeRing: View {
    var body: some View {
        Canvas { context, size in
            let r = min(size.width, size.height) * 0.33
            let center = CGPoint(x: size.width / 2, y: size.height / 2 + 6)
            let angles: [Double] = [-30, 30, 90, 150, 210, 270]
            let points = angles.map { a in
                CGPoint(x: center.x + r * cos(a * .pi / 180), y: center.y + r * sin(a * .pi / 180))
            }
            var ring = Path()
            ring.addLines(points)
            ring.closeSubpath()

            // Halftone-ish fill and the misregistered second ink.
            context.fill(ring, with: .color(Theme.green.opacity(0.07)))
            context.stroke(ring.offsetBy(dx: 2.2, dy: 1.6), with: .color(Theme.vermilion.opacity(0.4)),
                           style: StrokeStyle(lineWidth: 4, lineJoin: .round))
            context.stroke(ring, with: .color(Theme.ink), style: StrokeStyle(lineWidth: 4, lineJoin: .round))

            for (i, p) in points.enumerated() {
                let dx = (p.x - center.x) / r, dy = (p.y - center.y) / r
                if (1...4).contains(i) {
                    var bond = Path()
                    bond.move(to: p)
                    bond.addLine(to: CGPoint(x: p.x + dx * 18, y: p.y + dy * 18))
                    context.stroke(bond, with: .color(Theme.ink), lineWidth: 2)
                    context.draw(Text("OH").font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.soft),
                                 at: CGPoint(x: p.x + dx * 30, y: p.y + dy * 28))
                }
                if i == 0 {
                    let circle = Path(ellipseIn: CGRect(x: p.x - 11, y: p.y - 11, width: 22, height: 22))
                    context.fill(circle, with: .color(Theme.card))
                    context.stroke(circle, with: .color(Theme.vermilion), lineWidth: 2.2)
                    context.draw(Text("O").font(.system(size: 11, weight: .semibold, design: .monospaced)).foregroundStyle(Theme.vermilion), at: p)
                } else {
                    context.fill(Path(ellipseIn: CGRect(x: p.x - 4.5, y: p.y - 4.5, width: 9, height: 9)), with: .color(Theme.ink))
                }
            }
            let c5 = points[5]
            var arm = Path()
            arm.move(to: c5)
            arm.addLine(to: CGPoint(x: c5.x - 16, y: c5.y - 18))
            context.stroke(arm, with: .color(Theme.ink), lineWidth: 2)
            context.draw(Text("CH₂OH").font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.soft),
                         at: CGPoint(x: c5.x - 22, y: c5.y - 28))
        }
        .accessibilityHidden(true)
    }
}
