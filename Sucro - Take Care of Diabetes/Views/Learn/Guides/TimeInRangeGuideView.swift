//
//  TimeInRangeGuideView.swift
//  Sucro - Take Care of Diabetes
//
//  Shows the international consensus time-in-range goals for many adults
//  with type 1 or type 2 diabetes. These use fixed lines (54, 70, 180,
//  250 mg/dL), not the user's own thresholds.
//

import SwiftUI

struct TimeInRangeGuideView: View {
    @Environment(SettingsStore.self) private var settings

    private struct Band: Identifiable {
        let zone: GlucoseZone
        let range: (Double?, Double?)
        /// The share of the bar this band gets, in percent.
        let share: Double
        let goal: String
        var id: String { zone.name }
    }

    private let bands: [Band] = [
        Band(zone: .urgentHigh, range: (250, nil), share: 5, goal: "Under 5%"),
        Band(zone: .high, range: (180, 250), share: 20, goal: "Under 25%, with the band above"),
        Band(zone: .inRange, range: (70, 180), share: 70, goal: "Over 70%"),
        Band(zone: .low, range: (54, 70), share: 4, goal: "Under 4%, with the band below"),
        Band(zone: .urgentLow, range: (nil, 54), share: 1, goal: "Under 1%")
    ]

    var body: some View {
        GuidePage(guide: .timeInRange) {
            GuideSection(title: "A Day in Range") {
                Text("Time in range is the share of the day your glucose spends between \(settings.glucoseValueString(70)) and \(settings.formattedGlucose(180)). A common goal for many adults is more than 70%, about 17 hours a day.")
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 16) {
                    DayRing(fraction: 0.7)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("17 h")
                            .font(.largeTitle.bold())
                            .foregroundStyle(GlucoseZone.inRange.color)
                        Text("in range out of 24 hours")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .card()
            }

            GuideSection(title: "The Goals") {
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 2) {
                        ForEach(bands) { band in
                            Rectangle()
                                .fill(band.zone.bandColor.gradient)
                                .frame(height: max(8, 260 * band.share / 100))
                        }
                    }
                    .frame(width: 36)
                    .clipShape(.rect(cornerRadius: 10))
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(bands) { band in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(label(for: band.range))
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                                Text(band.goal)
                                    .font(.subheadline)
                                    .foregroundStyle(band.zone.color)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
                .card()
                Text("Goals are different for older adults, children and during pregnancy. Ask your care team which apply to you.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            GuideSection(title: "Small Steps Count") {
                Label {
                    Text("Every extra 5% of time in range, about 72 minutes a day, makes a real difference. Lows come first: cutting time below range matters most.")
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(.tint)
                }
                .card()
                Label {
                    Text("Trends shows your own time in range, measured against the lines you set.")
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "iphone")
                        .foregroundStyle(.tint)
                }
                .card()
            }

            GuideRelatedTerms(termIDs: ["time-in-range", "time-below-range", "cgm", "a1c"])
        }
    }

    private func label(for range: (Double?, Double?)) -> String {
        let v = settings.glucoseValueString
        let unit = settings.glucoseUnit
        switch range {
        case let (low?, high?): return "\(v(low))–\(v(high)) \(unit)"
        case let (low?, nil): return "Above \(v(low)) \(unit)"
        case let (nil, high?): return "Below \(v(high)) \(unit)"
        default: return ""
        }
    }
}

/// A ring that fills to the in-range share of a day.
private struct DayRing: View {
    let fraction: Double
    @State private var shown: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.tertiarySystemFill), lineWidth: 12)
            Circle()
                .trim(from: 0, to: shown)
                .stroke(GlucoseZone.inRange.color.gradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(shown, format: .percent.precision(.fractionLength(0)))
                .font(.headline)
                .monospacedDigit()
                .contentTransition(.numericText(value: shown))
        }
        .frame(width: 88, height: 88)
        .onAppear {
            withAnimation(.smooth(duration: 1.0).delay(0.2)) { shown = fraction }
        }
        .accessibilityElement()
        .accessibilityLabel("70 percent of the day in range")
    }
}

#Preview {
    NavigationStack {
        TimeInRangeGuideView()
            .glossaryDestinations()
    }
    .environment(SettingsStore())
}
