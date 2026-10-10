//
//  GlucoseMeter.swift
//  Sucro - Take Care of Diabetes
//
//  A printed fingerstick meter with a test strip in it. The screen shows
//  the value being logged in its zone ink, so the reading on Today looks
//  like the meter in your hand.
//

import SwiftUI

struct GlucoseMeter: View {
    let value: String
    let unit: String
    let zone: GlucoseZone

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var beading = false

    var body: some View {
        ZStack(alignment: .top) {
            strip
            meterBody
                .padding(.top, 54)
        }
        .frame(maxWidth: 210)
        .accessibilityElement()
        .accessibilityLabel("Meter reading \(value) \(unit), \(zone.name)")
        .onAppear { beading = !reduceMotion }
    }

    /// Test strip poking out of the top, with a drop of blood on its tip.
    private var strip: some View {
        ZStack(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: 6, topTrailingRadius: 6)
                .fill(Theme.card)
                .overlay(UnevenRoundedRectangle(topLeadingRadius: 6, topTrailingRadius: 6).strokeBorder(Theme.ink, lineWidth: 1.5))
                .overlay(alignment: .bottom) {
                    // Contact bars where the strip meets the meter.
                    HStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { _ in Theme.ink.opacity(0.5).frame(width: 2, height: 14) }
                    }
                    .padding(.bottom, 6)
                }
                .frame(width: 34, height: 70)
            Drop()
                .fill(Theme.vermilion)
                .frame(width: 16, height: 21)
                .scaleEffect(beading ? 1.08 : 0.94, anchor: .bottom)
                .animation(beading ? .easeInOut(duration: 1.6).repeatForever(autoreverses: true) : nil, value: beading)
                .offset(y: -12)
        }
    }

    private var meterBody: some View {
        VStack(spacing: 14) {
            // The screen.
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.system(size: 52, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(zone.color)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                HStack {
                    Text(zone.name)
                    Spacer()
                    Text(unit)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.soft)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(zone.color.opacity(0.08), in: .rect(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.ink, lineWidth: 1.5))

            // The meter's buttons, for the look of the thing.
            HStack(spacing: 22) {
                Circle().strokeBorder(Theme.ink, lineWidth: 1.5).frame(width: 18, height: 18)
                Circle().fill(Theme.green).overlay(Circle().strokeBorder(Theme.ink, lineWidth: 1.5)).frame(width: 22, height: 22)
                Circle().strokeBorder(Theme.ink, lineWidth: 1.5).frame(width: 18, height: 18)
            }
        }
        .padding(16)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 26).fill(Theme.card)
                Hatch().stroke(Theme.ink.opacity(0.18), lineWidth: 0.8)
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                    .mask(LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom))
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(Theme.ink, lineWidth: 1.5))
        .shadow(color: Theme.ink.opacity(0.1), radius: 10, y: 5)
    }

    private struct Drop: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let w = rect.width, h = rect.height
            path.move(to: CGPoint(x: w / 2, y: 0))
            path.addCurve(to: CGPoint(x: w, y: h * 0.66), control1: CGPoint(x: w * 0.6, y: h * 0.22), control2: CGPoint(x: w, y: h * 0.4))
            path.addArc(center: CGPoint(x: w / 2, y: h * 0.66), radius: w / 2, startAngle: .zero, endAngle: .degrees(180), clockwise: false)
            path.addCurve(to: CGPoint(x: w / 2, y: 0), control1: CGPoint(x: 0, y: h * 0.4), control2: CGPoint(x: w * 0.4, y: h * 0.22))
            return path
        }
    }

    /// Diagonal shading lines, like the pen's barrel.
    private struct Hatch: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            for x in stride(from: -rect.height, through: rect.width, by: 6) {
                path.move(to: CGPoint(x: x, y: rect.maxY))
                path.addLine(to: CGPoint(x: x + rect.height * 0.5, y: rect.maxY - rect.height * 0.5))
            }
            return path
        }
    }
}

#Preview {
    GlucoseMeter(value: "112", unit: "mg/dL", zone: .inRange)
        .padding(40)
        .background(Theme.paper)
}
