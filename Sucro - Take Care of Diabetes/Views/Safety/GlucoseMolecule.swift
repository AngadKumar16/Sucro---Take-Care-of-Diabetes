//
//  GlucoseMolecule.swift
//  Sucro - Take Care of Diabetes
//
//  A printed glucose ring (Haworth-style), inked in green with a slightly
//  out-of-register vermilion pass behind it. The bonds draw themselves in
//  like a pen stroke the first time it appears.
//

import SwiftUI

struct GlucoseMolecule: View {
    /// Bonds fully drawn at 1.
    var progress: Double = 1

    /// Drawing space; the view scales it to fit its width.
    private static let canvas = CGSize(width: 260, height: 190)
    private static let center = CGPoint(x: 130, y: 100)
    private static let radius: CGFloat = 40
    private static let bond: CGFloat = 30

    /// Ring atoms clockwise from the ring oxygen (upper right).
    private static let ring: [(angle: Double, label: String?, substituent: String?)] = [
        (-30, "O", nil),
        (30, nil, "OH"),        // C1
        (90, nil, "OH"),        // C2
        (150, nil, "OH"),       // C3
        (210, nil, "HO"),       // C4
        (270, nil, "CH2OH"),    // C5
    ]

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / Self.canvas.width
            ZStack(alignment: .topLeading) {
                Bonds()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.vermilion.opacity(0.45), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    .offset(x: 2.5 * scale, y: 2 * scale)
                Bonds()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.green, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))

                ForEach(Array(Self.ring.enumerated()), id: \.offset) { _, atom in
                    if let label = atom.label {
                        atomLabel(label, at: Self.vertex(atom.angle), scale: scale, color: Theme.vermilion)
                    }
                    if let substituent = atom.substituent {
                        atomLabel(substituent, at: Self.vertex(atom.angle, extra: Self.bond + 14), scale: scale, color: Theme.ink)
                    }
                }
                .opacity(progress > 0.7 ? 1 : 0)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .aspectRatio(Self.canvas.width / Self.canvas.height, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func atomLabel(_ text: String, at point: CGPoint, scale: CGFloat, color: Color) -> some View {
        // New York has no subscript digits, so a digit is set small and low.
        text.reduce(Text("")) { label, character in
            character.isNumber
                ? label + Text(String(character)).font(.system(size: 10 * scale, weight: .semibold, design: .serif)).baselineOffset(-4 * scale)
                : label + Text(String(character))
        }
            .font(.system(size: 15 * scale, weight: .semibold, design: .serif))
            .foregroundStyle(color)
            .padding(.horizontal, 3 * scale)
            .background(Theme.card)
            .fixedSize()
            .position(x: point.x * scale, y: point.y * scale)
    }

    fileprivate static func vertex(_ degrees: Double, extra: CGFloat = 0) -> CGPoint {
        let r = radius + extra
        let a = CGFloat(degrees) * .pi / 180
        return CGPoint(x: center.x + r * cos(a), y: center.y + r * sin(a))
    }

    /// The ring followed by one outward bond per carbon, as a single path so
    /// trim draws it in one continuous stroke.
    private struct Bonds: Shape {
        func path(in rect: CGRect) -> Path {
            let s = rect.width / GlucoseMolecule.canvas.width
            func p(_ point: CGPoint) -> CGPoint { CGPoint(x: point.x * s, y: point.y * s) }
            var path = Path()
            let angles = GlucoseMolecule.ring.map(\.angle)
            path.move(to: p(GlucoseMolecule.vertex(angles[0])))
            for angle in angles.dropFirst() + [angles[0]] {
                path.addLine(to: p(GlucoseMolecule.vertex(angle)))
            }
            for atom in GlucoseMolecule.ring where atom.substituent != nil {
                path.move(to: p(GlucoseMolecule.vertex(atom.angle)))
                path.addLine(to: p(GlucoseMolecule.vertex(atom.angle, extra: GlucoseMolecule.bond)))
            }
            return path
        }
    }
}

#Preview {
    GlucoseMolecule()
        .padding(40)
        .background(Theme.paper)
}
