//
//  SproutView.swift
//  DiabetesCare
//
//  The little plant that grows with you: a seed in a pot that sprouts,
//  leafs out, buds and blooms as skills are learned and streaks build.
//  It sways gently unless Reduce Motion is on.
//

import SwiftUI

struct SproutView: View {
    let growth: SproutGrowth
    var size: CGFloat = 120

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            plant
                .frame(width: size, height: size * 0.8)
                .phaseAnimator(reduceMotion || growth == .seed ? [0.0] : [-2.5, 2.5]) { content, angle in
                    content.rotationEffect(.degrees(angle), anchor: .bottom)
                } animation: { _ in
                    .easeInOut(duration: 2.6)
                }
                .padding(.bottom, size * 0.22)
            Pot()
                .fill(Theme.amber.opacity(0.85))
                .overlay(Pot().stroke(Theme.ink.opacity(0.25), lineWidth: 1))
                .frame(width: size * 0.5, height: size * 0.28)
        }
        .frame(width: size, height: size)
        .animation(reduceMotion ? nil : .bouncy(duration: 0.7), value: growth)
        .accessibilityElement()
        .accessibilityLabel("Your plant: \(growth.name)")
    }

    private var plant: some View {
        Canvas { context, canvas in
            let w = canvas.width, h = canvas.height
            let base = CGPoint(x: w / 2, y: h)
            let stemHeight: CGFloat = switch growth {
            case .seed: 0
            case .sprout: h * 0.3
            case .seedling: h * 0.5
            case .plant: h * 0.7
            case .bud, .flower: h * 0.85
            }
            let green = Theme.green

            if growth == .seed {
                let seed = Path(ellipseIn: CGRect(x: base.x - 7, y: base.y - 10, width: 14, height: 10))
                context.fill(seed, with: .color(Theme.amber))
                return
            }

            let top = CGPoint(x: base.x, y: base.y - stemHeight)
            var stem = Path()
            stem.move(to: base)
            stem.addQuadCurve(to: top, control: CGPoint(x: base.x + w * 0.06, y: base.y - stemHeight * 0.5))
            context.stroke(stem, with: .color(green), style: StrokeStyle(lineWidth: max(3, w * 0.035), lineCap: .round))

            // Pairs of leaves up the stem, more as it grows.
            let pairs = switch growth {
            case .seed: 0
            case .sprout: 1
            case .seedling: 1
            case .plant: 2
            case .bud, .flower: 3
            }
            for index in 0..<pairs {
                let t = CGFloat(index + 1) / CGFloat(pairs + 1)
                let at = CGPoint(x: base.x + w * 0.03 * t, y: base.y - stemHeight * (growth == .sprout ? 0.9 : t))
                let length = w * (growth == .sprout ? 0.16 : 0.24) * (1 - t * 0.25)
                for side in [-1.0, 1.0] {
                    let leaf = leafPath(at: at, length: length, angle: side < 0 ? 200 : -20)
                    context.fill(leaf, with: .color(green.opacity(side < 0 ? 0.85 : 1)))
                }
            }

            switch growth {
            case .bud:
                let bud = Path(ellipseIn: CGRect(x: top.x - 7, y: top.y - 16, width: 14, height: 18))
                context.fill(bud, with: .color(Theme.vermilion.opacity(0.8)))
            case .flower:
                for petal in 0..<6 {
                    let angle = CGFloat(petal) / 6 * 2 * .pi
                    let center = CGPoint(x: top.x + cos(angle) * 11, y: top.y - 8 + sin(angle) * 11)
                    context.fill(Path(ellipseIn: CGRect(x: center.x - 8, y: center.y - 8, width: 16, height: 16)),
                                 with: .color(Theme.vermilion.opacity(0.75)))
                }
                context.fill(Path(ellipseIn: CGRect(x: top.x - 7, y: top.y - 15, width: 14, height: 14)), with: .color(Theme.amber))
            default:
                break
            }
        }
    }

    private func leafPath(at point: CGPoint, length: CGFloat, angle degrees: Double) -> Path {
        let angle = CGFloat(degrees * .pi / 180)
        let tip = CGPoint(x: point.x + cos(angle) * length, y: point.y + sin(angle) * length)
        let normal = angle + .pi / 2
        let mid = CGPoint(x: (point.x + tip.x) / 2, y: (point.y + tip.y) / 2)
        let width = length * 0.4
        var path = Path()
        path.move(to: point)
        path.addQuadCurve(to: tip, control: CGPoint(x: mid.x + cos(normal) * width, y: mid.y + sin(normal) * width))
        path.addQuadCurve(to: point, control: CGPoint(x: mid.x - cos(normal) * width, y: mid.y - sin(normal) * width))
        return path
    }
}

private struct Pot: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let lip = rect.height * 0.28
        path.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: lip), cornerSize: CGSize(width: 4, height: 4))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + lip))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.minY + lip))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ScrollView(.horizontal) {
        HStack {
            ForEach(SproutGrowth.allCases, id: \.self) { growth in
                VStack {
                    SproutView(growth: growth)
                    Text(growth.name)
                }
            }
        }
    }
}
