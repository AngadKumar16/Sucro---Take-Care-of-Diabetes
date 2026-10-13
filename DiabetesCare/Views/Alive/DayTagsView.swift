//
//  DayTagsView.swift
//  DiabetesCare
//
//  "How's today?": tags for the kind of day it is, and the sick-day
//  checklist that appears when today is tagged Sick. The checklist is
//  general information; the person's sick-day plan comes first.
//

import SwiftUI

struct DayTagsRow: View {
    let selected: Set<DayTag>
    let onToggle: (DayTag) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How's today?")
                .friendlyLabel()
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(DayTag.allCases) { tag in
                        let isOn = selected.contains(tag)
                        Button {
                            onToggle(tag)
                        } label: {
                            Label(tag.name, systemImage: tag.symbol)
                                .font(.subheadline.weight(isOn ? .semibold : .regular))
                                .foregroundStyle(isOn ? Theme.onAccent : Theme.ink)
                                .padding(.horizontal, 12)
                                .frame(minHeight: 36)
                                .background(isOn ? Theme.green : Theme.card, in: .capsule)
                                .overlay(Capsule().strokeBorder(isOn ? .clear : Theme.rule))
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isOn ? .isSelected : [])
                        .accessibilityIdentifier("dayTag.\(tag.rawValue)")
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .sensoryFeedback(.selection, trigger: selected)
        }
    }
}

/// A checklist for a sick day, with the latest ketone check.
struct SickDayCard: View {
    let latestKetone: KetoneReading?
    let onLogKetones: () -> Void
    let onLearnMore: () -> Void

    /// Checked items, per day.
    @AppStorage("sickDay.checked") private var checkedStorage = ""

    private static let items: [(id: String, text: String)] = [
        ("glucose", String(localized: "Check glucose every 2–3 hours")),
        ("ketones", String(localized: "Check ketones every 3–4 hours, or when glucose is high")),
        ("fluids", String(localized: "Sip water or sugar-free drinks every hour")),
        ("plan", String(localized: "Follow your sick-day plan for insulin")),
        ("call", String(localized: "Call your care team if ketones are moderate or high, or you're throwing up")),
    ]

    private var todayKey: String { Date().formatted(.iso8601.year().month().day()) }

    private var checked: Set<String> {
        let parts = checkedStorage.split(separator: "|", maxSplits: 1).map(String.init)
        guard parts.count == 2, parts[0] == todayKey else { return [] }
        return Set(parts[1].split(separator: ",").map(String.init))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Sick Day", systemImage: "thermometer.medium")
                    .font(.headline)
                    .foregroundStyle(Theme.vermilion)
                Spacer()
                Button("About Ketones", action: onLearnMore)
                    .font(.subheadline)
            }
            ForEach(Self.items, id: \.id) { item in
                let isDone = checked.contains(item.id)
                Button {
                    toggle(item.id)
                } label: {
                    Label {
                        Text(item.text)
                            .foregroundStyle(isDone ? Theme.soft : Theme.ink)
                            .strikethrough(isDone)
                            .multilineTextAlignment(.leading)
                    } icon: {
                        Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(Theme.green)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.plain)
                .accessibilityValue(isDone ? "Done" : "Not done")
            }
            HStack {
                if let latestKetone, let time = latestKetone.timestamp {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last ketones: \(latestKetone.displayValue)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(latestKetone.level >= .high ? Theme.vermilion : Theme.ink)
                        Text("\(latestKetone.level.name) · \(time.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundStyle(Theme.soft)
                    }
                } else {
                    Text("No ketone check yet today.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.soft)
                }
                Spacer()
                Button("Log Ketones", systemImage: "flask", action: onLogKetones)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.green)
                    .accessibilityIdentifier("sickDayLogKetones")
            }
        }
        .softPanel(border: Theme.vermilion.opacity(0.6))
        .sensoryFeedback(.selection, trigger: checked)
        .accessibilityIdentifier("sickDayCard")
    }

    private func toggle(_ id: String) {
        var set = checked
        if set.contains(id) { set.remove(id) } else { set.insert(id) }
        withAnimation(.snappy) {
            checkedStorage = todayKey + "|" + set.sorted().joined(separator: ",")
        }
    }
}
