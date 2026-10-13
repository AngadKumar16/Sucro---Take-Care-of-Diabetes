//
//  Celebration.swift
//  DiabetesCare
//
//  A short burst of falling leaves for milestones (a 7-day streak, a new
//  stage). With Reduce Motion on, the message shows without the leaves.
//

import SwiftUI

/// A milestone to celebrate, shown for a few seconds over Today.
struct Milestone: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let symbol: String
}

struct CelebrationOverlay: View {
    let milestone: Milestone

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()

    var body: some View {
        ZStack(alignment: .top) {
            if !reduceMotion {
                LeafBurst(start: start)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            HStack(spacing: 12) {
                Image(systemName: milestone.symbol)
                    .font(.title)
                    .foregroundStyle(Theme.green)
                    .symbolEffect(.bounce, options: .nonRepeating, value: reduceMotion ? nil : milestone.id)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(milestone.title)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text(milestone.message)
                        .font(.subheadline)
                        .foregroundStyle(Theme.soft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .softPanel(padding: 14, border: Theme.green)
            .padding(.horizontal)
            .accessibilityElement(children: .combine)
        }
    }
}

/// Leaves drifting down and sideways from the top of the screen.
private struct LeafBurst: View {
    let start: Date
    private static let leaves: [Leaf] = (0..<28).map { Leaf(seed: $0) }

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(start)
            Canvas { context, size in
                for leaf in Self.leaves {
                    let t = elapsed - leaf.delay
                    guard t > 0, t < 3.2 else { continue }
                    let x = size.width * leaf.x + sin(t * leaf.wobble) * 24
                    let y = -20 + t * leaf.speed * size.height / 3
                    let opacity = t > 2.4 ? max(0, 1 - (t - 2.4) / 0.8) : 1
                    var copy = context
                    copy.translateBy(x: x, y: y)
                    copy.rotate(by: .degrees(leaf.spin * t * 90))
                    copy.opacity = opacity
                    let shape = Path(ellipseIn: CGRect(x: -6, y: -3, width: 12, height: 6))
                    copy.fill(shape, with: .color(leaf.tint))
                }
            }
        }
    }

    private struct Leaf {
        let x: Double
        let delay: Double
        let speed: Double
        let wobble: Double
        let spin: Double
        let tint: Color

        init(seed: Int) {
            // Fixed, varied values so every burst looks natural but stable.
            let r = { (n: Int) in Double((seed * 7919 + n * 104_729) % 1000) / 1000 }
            x = r(1)
            delay = r(2) * 0.6
            speed = 0.8 + r(3) * 0.7
            wobble = 2 + r(4) * 3
            spin = r(5) > 0.5 ? 1 : -1
            tint = [Theme.green, Theme.green.opacity(0.7), Theme.amber, Theme.vermilion.opacity(0.7)][seed % 4]
        }
    }
}
