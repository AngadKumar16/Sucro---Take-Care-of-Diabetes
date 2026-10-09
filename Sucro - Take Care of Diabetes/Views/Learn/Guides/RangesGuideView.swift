//
//  RangesGuideView.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// Walks through the user's own five glucose zones, top to bottom, with
/// what each means and what to do.
struct RangesGuideView: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        GuidePage(guide: .ranges) {
            GuideSection(title: "Your Lines") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Four lines split your glucose into five zones. These are the ones you've set.")
                        .foregroundStyle(.secondary)
                    GlucoseRangeBar(thresholds: settings.thresholds)
                }
                .card()
            }

            GuideSection(title: "Zone by Zone") {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(GlucoseZone.topDown.enumerated()), id: \.element) { index, zone in
                        ZoneRow(zone: zone, range: rangeText(for: zone), isFirst: index == 0,
                                isLast: index == GlucoseZone.topDown.count - 1)
                    }
                }
            }

            GuideSection(title: "Changing Your Lines") {
                Label {
                    Text("Drag the sliders in Settings › Glucose. Targets differ by person, age and situation, such as pregnancy, so set them with your care team.")
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(.tint)
                }
                .card()
            }

            GuideRelatedTerms(termIDs: ["target-range", "hypoglycemia", "hyperglycemia", "ketones"])
        }
    }

    private func rangeText(for zone: GlucoseZone) -> String {
        let t = settings.thresholds
        let v = settings.glucoseValueString
        let unit = settings.glucoseUnit
        switch zone {
        case .urgentHigh: return "Above \(v(t.urgentHigh)) \(unit)"
        case .high: return "\(v(t.targetHigh))–\(v(t.urgentHigh)) \(unit)"
        case .inRange: return "\(v(t.targetLow))–\(v(t.targetHigh)) \(unit)"
        case .low: return "\(v(t.urgentLow))–\(v(t.targetLow)) \(unit)"
        case .urgentLow: return "Below \(v(t.urgentLow)) \(unit)"
        }
    }
}

/// One zone on a vertical rail, like a stop on a line map.
private struct ZoneRow: View {
    let zone: GlucoseZone
    let range: String
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // The rail: a continuous colored line with a badge per zone.
            VStack(spacing: 0) {
                Rectangle()
                    .fill(isFirst ? .clear : zone.bandColor)
                    .frame(width: 4, height: 12)
                Image(systemName: zone.symbol)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(zone.bandColor.gradient, in: .circle)
                Rectangle()
                    .fill(isLast ? .clear : zone.bandColor)
                    .frame(width: 4)
                    .frame(maxHeight: .infinity)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(zone.name)
                        .font(.headline)
                    Spacer()
                    Text(range)
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(zone.color)
                }
                Text(zone.meaning)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                Label {
                    Text(zone.action)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: zone.needsAction ? "hand.raised.fill" : "info.circle.fill")
                        .foregroundStyle(zone.color)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(14)
            .printSurface()
            .padding(.top, 4)
            .padding(.bottom, isLast ? 0 : 12)
        }
        .accessibilityElement(children: .combine)
    }
}

private extension GlucoseZone {
    var meaning: String {
        switch self {
        case .urgentHigh: return "Well above your target. Staying here for hours raises the risk of ketones."
        case .high: return "Above target but not an emergency. Common for a while after meals."
        case .inRange: return "Where you aim to spend most of the day. It's the green band on Trends."
        case .low: return "Below target. Your body is running short on glucose."
        case .urgentLow: return "A serious low. Thinking and coordination can quickly get worse."
        }
    }

    var action: String {
        switch self {
        case .urgentHigh: return "Follow your care team's plan for highs. Check ketones if you have type 1 or feel sick. DiabetesCare alerts you here."
        case .high: return "If it stays high for hours, look for a reason: a missed dose, illness, stress or a pump site problem."
        case .inRange: return "Nothing to do. Keep logging so Trends can show your patterns."
        case .low: return "Treat right away with fast-acting carbs, then check again. DiabetesCare alerts you here."
        case .urgentLow: return "Treat straight away and don't drive. If someone can't swallow safely, they need glucagon and emergency help."
        }
    }
}

#Preview {
    NavigationStack {
        RangesGuideView()
            .glossaryDestinations()
    }
    .environment(SettingsStore())
}
