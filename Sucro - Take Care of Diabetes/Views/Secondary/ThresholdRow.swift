//
//  ThresholdRow.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// One glucose threshold set on a ruler tape: scrub the scale under a fixed
/// needle, like the zoom ruler in Camera. Native scrolling gives the fling
/// and deceleration; view-aligned snapping lands on whole steps.
struct ThresholdRow: View {
    @Environment(SettingsStore.self) private var settings
    let title: String
    let zone: GlucoseZone
    @Binding var value: Double
    let bounds: ClosedRange<Double>

    private let step = SettingsStore.thresholdStep

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(zone.bandColor)
                        .frame(width: 8, height: 8)
                    Text(title)
                        .instrumentLabel()
                }
                Spacer()
                Text(settings.glucoseValueString(value))
                    .font(.system(size: 32, weight: .semibold, design: .serif).monospacedDigit())
                    .contentTransition(.numericText(value: value))
                    .foregroundStyle(zone.color)
                Text(settings.glucoseUnit)
                    .font(Theme.mono(.caption))
                    .foregroundStyle(.secondary)
            }
            .accessibilityHidden(true)

            RulerTape(value: $value, bounds: bounds, step: step, needle: zone.color)
                .accessibilityRepresentation {
                    Slider(value: $value, in: safeRange, step: step) {
                        Text(title)
                    }
                    .accessibilityValue(settings.formattedGlucose(value))
                    .accessibilityIdentifier("threshold.\(title)")
                }
        }
        .padding(.vertical, 4)
        .animation(.snappy, value: value)
    }

    /// The neighbors can squeeze a threshold down to one allowed value; a
    /// slider still needs some span.
    private var safeRange: ClosedRange<Double> {
        bounds.upperBound - bounds.lowerBound < step
            ? bounds.lowerBound...(bounds.lowerBound + step)
            : bounds
    }
}

/// A horizontal scale from 40 to 400 mg/dL that scrolls under a fixed
/// center needle. Ticks outside `bounds` are dimmed; let go past them and
/// the tape springs back to the nearest allowed value.
struct RulerTape: View {
    @Environment(SettingsStore.self) private var settings
    @Binding var value: Double
    let bounds: ClosedRange<Double>
    let step: Double
    let needle: Color
    /// Width of one step on the tape. Narrower ticks for fine steps.
    var tickWidth: CGFloat = 9

    /// The tape covers the same span as the range bar.
    private static let scale = GlucoseRangeBar.scale

    @State private var position: Double?
    @State private var isScrolling = false

    private var ticks: [Double] {
        Array(stride(from: Self.scale.lowerBound, through: Self.scale.upperBound, by: step))
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(ticks, id: \.self) { tick in
                        Tick(value: tick, allowed: bounds.contains(tick), zone: settings.zone(for: tick))
                            .frame(width: tickWidth)
                            .id(tick)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, (proxy.size.width - tickWidth) / 2, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $position, anchor: .center)
            .scrollIndicators(.hidden)
            .onScrollPhaseChange { _, phase in
                isScrolling = phase != .idle
                if phase == .idle { springBackIfNeeded() }
            }
        }
        .frame(height: 46)
        .mask {
            LinearGradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: 0.18),
                .init(color: .black, location: 0.82),
                .init(color: .clear, location: 1)
            ], startPoint: .leading, endPoint: .trailing)
        }
        .overlay(alignment: .top) {
            // The needle stays put; the scale moves under it.
            VStack(spacing: 0) {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 8))
                Capsule()
                    .frame(width: 2.5, height: 26)
            }
            .foregroundStyle(needle)
            .offset(y: -6)
            .allowsHitTesting(false)
        }
        .onAppear { position = nearestTick(to: value) }
        .onChange(of: position) { _, new in
            guard let new else { return }
            let clamped = min(max(new, bounds.lowerBound), bounds.upperBound)
            if clamped != value { value = clamped }
        }
        .onChange(of: value) { _, new in
            // Moved from outside, e.g. Reset to Common Defaults.
            guard !isScrolling, position != new else { return }
            withAnimation(.snappy) { position = nearestTick(to: new) }
        }
        // A detent for every step, a firmer one on each 25 mg/dL mark.
        .sensoryFeedback(trigger: value) { _, new in
            new.truncatingRemainder(dividingBy: 25) == 0
                ? .impact(weight: .medium, intensity: 0.8)
                : .selection
        }
    }

    private func springBackIfNeeded() {
        guard let position, !bounds.contains(position) else { return }
        withAnimation(.snappy) {
            self.position = nearestTick(to: min(max(position, bounds.lowerBound), bounds.upperBound))
        }
    }

    private func nearestTick(to mgdl: Double) -> Double {
        let index = ((mgdl - Self.scale.lowerBound) / step).rounded()
        return min(max(Self.scale.lowerBound + index * step, Self.scale.lowerBound), Self.scale.upperBound)
    }

    /// One mark on the scale, with a zone-colored strip along its foot.
    private struct Tick: View {
        @Environment(SettingsStore.self) private var settings
        let value: Double
        let allowed: Bool
        let zone: GlucoseZone

        private var isMajor: Bool { value.truncatingRemainder(dividingBy: 50) == 0 }
        private var isMid: Bool { value.truncatingRemainder(dividingBy: 25) == 0 }

        var body: some View {
            VStack(spacing: 3) {
                Rectangle()
                    .fill(Theme.print)
                    .frame(width: isMajor ? 2 : 1, height: isMajor ? 18 : (isMid ? 13 : 8))
                    .frame(height: 18, alignment: .bottom)
                Rectangle()
                    .fill(zone.bandColor)
                    .frame(height: 6)
                Text(isMajor ? settings.glucoseValueString(value) : " ")
                    .font(Theme.mono(.caption2))
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .frame(width: 9)
            }
            .opacity(allowed ? 1 : 0.25)
            .accessibilityHidden(true)
        }
    }
}
