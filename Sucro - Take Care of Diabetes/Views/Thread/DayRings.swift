//
//  DayRings.swift
//  Sucro - Take Care of Diabetes
//
//  The thread wound into rings, one per day, like the rings of a tree.
//  The clock runs around each ring with midnight at the top, so the same
//  hour lines up across days and daily patterns show at a glance. The
//  oldest day is innermost and today is the outer ring. Glucose pushes the
//  line outward or inward within its ring. Tap a ring to unwind that day.
//

import SwiftUI

struct DayRings: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let samples: [GlucoseSample]
    /// Calendar days to draw, oldest first.
    let days: [Date]
    let now: Date
    let onSelectDay: (Date) -> Void

    /// 0...1, how much of each ring is drawn. Animates in on appear.
    @State private var progress: Double = 0

    var body: some View {
        RingsCanvas(samples: samples, days: days, now: now, progress: progress)
        .aspectRatio(1, contentMode: .fit)
        .contentShape(.circle)
        .gesture(
            SpatialTapGesture().onEnded { value in
                // Canvas size is needed to find the ring; GeometryReader
                // below records it.
                if let day = day(at: value.location) { onSelectDay(day) }
            }
        )
        .background { GeometryReader { proxy in Color.clear.preference(key: RingSizeKey.self, value: proxy.size) } }
        .onPreferenceChange(RingSizeKey.self) { canvasSize = $0 }
        .onAppear {
            if reduceMotion {
                progress = 1
            } else {
                withAnimation(.smooth(duration: 0.9)) { progress = 1 }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Glucose rings, one per day, today on the outside")
        .accessibilityChildren {
            ForEach(days, id: \.self) { day in
                Rectangle()
                    .accessibilityLabel(summary(for: day))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { onSelectDay(day) }
            }
        }
        .accessibilityIdentifier("glucoseRings")
    }

    @State private var canvasSize: CGSize = .zero

    // MARK: - Hit testing and accessibility

    private func day(at location: CGPoint) -> Date? {
        guard canvasSize != .zero else { return nil }
        let geometry = RingGeometry(size: canvasSize, count: days.count)
        let distance = hypot(location.x - geometry.center.x, location.y - geometry.center.y)
        let ring = Int(((distance - geometry.inner) / geometry.gap + 0.5).rounded(.down))
        return days.indices.contains(ring) ? days[ring] : nil
    }

    private func summary(for day: Date) -> String {
        let start = Calendar.current.startOfDay(for: day)
        let daySamples = samples.filter { $0.date >= start && $0.date < start.addingTimeInterval(86_400) }
        let name = day.formatted(.dateTime.weekday(.wide).month().day())
        guard !daySamples.isEmpty else { return "\(name): no readings" }
        let stats = GlucoseCalculator.calculateStatistics(samples: daySamples, thresholds: settings.thresholds)
        return "\(name): \(Int(stats.timeInRange.percentage.rounded())) percent in range, average \(settings.formattedGlucose(stats.average))"
    }
}


/// The drawing itself, separate so `progress` animates frame by frame.
private struct RingsCanvas: View, Animatable {
    @Environment(SettingsStore.self) private var settings
    let samples: [GlucoseSample]
    let days: [Date]
    let now: Date
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        Canvas { context, size in
            let geometry = RingGeometry(size: size, count: days.count)
            drawClock(in: &context, geometry: geometry)
            for (index, day) in days.enumerated() {
                drawRing(index: index, day: day, in: &context, geometry: geometry)
            }
        }
    }

    // MARK: - Drawing

    private func drawClock(in context: inout GraphicsContext, geometry: RingGeometry) {
        // Faint spokes every three hours; labeled at the quarters.
        for hour in stride(from: 0, to: 24, by: 3) {
            let angle = geometry.angle(hours: Double(hour))
            var spoke = Path()
            spoke.move(to: geometry.point(angle, geometry.inner - geometry.gap * 0.3))
            spoke.addLine(to: geometry.point(angle, geometry.outer + 4))
            context.stroke(spoke, with: .color(Theme.print.opacity(hour % 6 == 0 ? 0.18 : 0.08)), lineWidth: 1)

            if hour % 6 == 0 {
                let label = Text(hourLabel(hour))
                    .font(Theme.readout(.caption2))
                    .foregroundStyle(.secondary)
                context.draw(label, at: geometry.point(angle, geometry.outer + 14))
            }
        }
    }

    private func drawRing(index: Int, day: Date, in context: inout GraphicsContext, geometry: RingGeometry) {
        let base = geometry.radius(ring: index)
        // Swings reach a little into the neighboring rings, so big days
        // weave across the rings instead of hiding inside their own.
        let half = geometry.gap * 0.95

        // The target range as a faint band within the ring.
        let low = base + half * offset(settings.targetLow)
        let high = base + half * offset(settings.targetHigh)
        var band = Path()
        band.addArc(center: geometry.center, radius: (low + high) / 2, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        context.stroke(band, with: .color(GlucoseZone.inRange.color.opacity(0.1)), lineWidth: max(1, high - low))

        let start = Calendar.current.startOfDay(for: day)
        let end = start.addingTimeInterval(86_400)
        let daySamples = samples.filter { $0.date >= start && $0.date < end }
        guard !daySamples.isEmpty else { return }

        let drawUntil = start.addingTimeInterval(86_400 * progress)
        var path = Path()
        var previous: GlucoseSample?
        for sample in daySamples where sample.date <= drawUntil {
            let hours = sample.date.timeIntervalSince(start) / 3600
            let point = geometry.point(geometry.angle(hours: hours), base + half * offset(sample.mgdl))
            if let previous, sample.date.timeIntervalSince(previous.date) <= 3600 {
                path.addLine(to: point)
            } else {
                path.move(to: point)
            }
            previous = sample
        }
        let isToday = Calendar.current.isDate(day, inSameDayAs: now)
        context.stroke(path, with: .color(Theme.print.opacity(isToday ? 0.9 : 0.55)),
                       style: StrokeStyle(lineWidth: isToday ? 1.8 : 1.1, lineCap: .round, lineJoin: .round))

        // Out-of-range readings glow in their zone color.
        for sample in daySamples where sample.date <= drawUntil {
            let zone = settings.zone(for: sample.mgdl)
            guard zone != .inRange else { continue }
            let hours = sample.date.timeIntervalSince(start) / 3600
            let point = geometry.point(geometry.angle(hours: hours), base + half * offset(sample.mgdl))
            context.fill(Path(ellipseIn: CGRect(x: point.x - 1.6, y: point.y - 1.6, width: 3.2, height: 3.2)),
                         with: .color(zone.color))
        }

        // Today ends in a bead at the latest reading.
        if isToday, progress == 1, let last = daySamples.last {
            let hours = last.date.timeIntervalSince(start) / 3600
            let point = geometry.point(geometry.angle(hours: hours), base + half * offset(last.mgdl))
            context.fill(Path(ellipseIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)),
                         with: .color(settings.zone(for: last.mgdl).color))
        }
    }

    /// Where a value sits within its ring, -1 (inner edge) to 1 (outer).
    /// Log scale, like the low end of a meter: lows get more room.
    private func offset(_ mgdl: Double) -> Double {
        let clamped = min(max(mgdl, 40), 400)
        return log(clamped / 40) / log(10) * 2 - 1
    }

    private func hourLabel(_ hour: Int) -> String {
        switch hour {
        case 0: return "12a"
        case 6: return "6a"
        case 12: return "12p"
        default: return "6p"
        }
    }

}

private struct RingSizeKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) { value = nextValue() }
}

/// Shared geometry for drawing and hit testing.
private struct RingGeometry {
    let size: CGSize
    let count: Int

    var center: CGPoint { CGPoint(x: size.width / 2, y: size.height / 2) }
    /// Room outside the rings for the hour labels.
    var outer: CGFloat { min(size.width, size.height) / 2 - 24 }
    var inner: CGFloat { outer * 0.28 }
    var gap: CGFloat { count > 1 ? (outer - inner) / CGFloat(count - 1) : 0 }

    func radius(ring index: Int) -> CGFloat { inner + gap * CGFloat(index) }

    /// Midnight at the top, clockwise like a clock face.
    func angle(hours: Double) -> Angle { .degrees(hours / 24 * 360 - 90) }

    func point(_ angle: Angle, _ radius: CGFloat) -> CGPoint {
        CGPoint(x: center.x + radius * CGFloat(cos(angle.radians)), y: center.y + radius * CGFloat(sin(angle.radians)))
    }
}
