//
//  TimeInRangeTubes.swift
//  Sucro - Take Care of Diabetes
//
//  A rack of test tubes, one per day, each filled by how the day went:
//  low at the bottom, in range in the middle, high on top.
//

import SwiftUI

struct TimeInRangeTubes: View {
    @Environment(SettingsStore.self) private var settings
    /// Readings covering at least the last seven days.
    let samples: [GlucoseSample]
    var now = Date()

    struct Day: Identifiable {
        let date: Date
        let low: Double
        let inRange: Double
        let high: Double
        let count: Int
        var id: Date { date }
    }

    private var days: [Day] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        return (0..<7).reversed().compactMap { back in
            guard let start = calendar.date(byAdding: .day, value: -back, to: today),
                  let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
            let values = samples.filter { $0.date >= start && $0.date < end }.map(\.mgdl)
            guard !values.isEmpty else { return Day(date: start, low: 0, inRange: 0, high: 0, count: 0) }
            let total = Double(values.count)
            let low = Double(values.filter { settings.zone(for: $0).isLow }.count) / total
            let high = Double(values.filter { $0 > settings.targetHigh }.count) / total
            return Day(date: start, low: low, inRange: max(0, 1 - low - high), high: high, count: values.count)
        }
    }

    var body: some View {
        let days = days
        let withData = days.filter { $0.count > 0 }
        let overall = withData.isEmpty ? 0 : withData.map(\.inRange).reduce(0, +) / Double(withData.count)

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(overall, format: .percent.precision(.fractionLength(0)))
                    .font(.system(size: 40, weight: .semibold, design: .serif).monospacedDigit())
                    .foregroundStyle(Theme.green)
                Text("in range, past 7 days")
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
            }
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(days) { day in
                    tube(day)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 4)
            .background(alignment: .bottom) {
                // The rack.
                VStack(spacing: 0) {
                    Rectangle().fill(Theme.card).frame(height: 10)
                        .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: 1.5))
                    HStack {
                        Rectangle().fill(Theme.ink).frame(width: 6, height: 14)
                        Spacer()
                        Rectangle().fill(Theme.ink).frame(width: 6, height: 14)
                    }
                    .padding(.horizontal, 6)
                }
                .padding(.bottom, 22)
            }
            HStack(spacing: 14) {
                key(Theme.amber, "High")
                key(Theme.green, "In range")
                key(Theme.vermilion, "Low")
            }
            .font(.caption)
            .foregroundStyle(Theme.soft)
            .frame(maxWidth: .infinity)
        }
    }

    private func tube(_ day: Day) -> some View {
        let height: CGFloat = 150
        let isToday = Calendar.current.isDateInToday(day.date)
        return VStack(spacing: 4) {
            Text(day.count > 0 ? "\(Int((day.inRange * 100).rounded()))" : "–")
                .font(Theme.mono(.caption, weight: .semibold))
                .foregroundStyle(day.count > 0 ? Theme.green : Theme.soft)
            Rectangle().fill(isToday ? Theme.green : Theme.ink).frame(width: 32, height: 6)
            ZStack(alignment: .bottom) {
                if day.count > 0 {
                    VStack(spacing: 0) {
                        Rectangle().fill(Theme.amber.opacity(0.7)).frame(height: height * day.high)
                        Rectangle().fill(Theme.green.opacity(0.7)).frame(height: height * day.inRange)
                        Rectangle().fill(Theme.vermilion.opacity(0.75)).frame(height: height * day.low)
                    }
                    .overlay(HalftoneDots().opacity(0.35))
                }
            }
            .frame(width: 24, height: height, alignment: .bottom)
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 12, bottomTrailingRadius: 12))
            .overlay(UnevenRoundedRectangle(bottomLeadingRadius: 12, bottomTrailingRadius: 12).strokeBorder(Theme.ink, lineWidth: 2))
            .background(UnevenRoundedRectangle(bottomLeadingRadius: 12, bottomTrailingRadius: 12)
                .strokeBorder(Theme.vermilion.opacity(0.4), lineWidth: 2).offset(x: 2, y: 1.5))
            .padding(.bottom, 6)
            Text(day.date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.system(.footnote, design: .serif, weight: isToday ? .semibold : .regular))
                .foregroundStyle(Theme.ink)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(day.date.formatted(.dateTime.weekday(.wide)))
        .accessibilityValue(day.count > 0
            ? "\(Int((day.inRange * 100).rounded())) percent in range, \(Int((day.low * 100).rounded())) percent low, \(Int((day.high * 100).rounded())) percent high"
            : "No readings")
    }

    private func key(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 5) {
            Rectangle().fill(color.opacity(0.8)).frame(width: 12, height: 12).overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: 1))
            Text(text)
        }
    }
}

/// A fine dot screen laid over a fill, like a halftone print.
struct HalftoneDots: View {
    var body: some View {
        Canvas { context, size in
            for x in stride(from: 2.5, to: size.width, by: 5) {
                for y in stride(from: 2.5, to: size.height, by: 5) {
                    context.fill(Path(ellipseIn: CGRect(x: x - 1.2, y: y - 1.2, width: 2.4, height: 2.4)), with: .color(Theme.card))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
