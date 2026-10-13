//
//  TodayCards.swift
//  DiabetesCare
//
//  The parts of Today that make it feel aware of the day: what's next,
//  streaks, how the night went, and a short story of the day so far.
//

import SwiftUI

/// One line under the greeting about what's coming up.
struct NextUpLine: View {
    let now: Date
    let lowRecheckAt: Date?
    let reminders: [Reminder]
    let siteDue: Date?
    let loggingStreak: Int

    var body: some View {
        Group {
            if let lowRecheckAt, lowRecheckAt > now {
                Label {
                    Text("Recheck glucose in \(Text(timerInterval: now...lowRecheckAt, countsDown: true))")
                } icon: {
                    Image(systemName: "timer")
                }
                .foregroundStyle(Theme.vermilion)
            } else if let next = reminders.filter({ $0.time > now && $0.time.timeIntervalSince(now) < 12 * 3600 }).min(by: { $0.time < $1.time }) {
                Label("\(next.title) at \(next.time.formatted(date: .omitted, time: .shortened))", systemImage: "bell")
            } else if let siteDue, let text = siteText(siteDue) {
                Label(text, systemImage: "bandage")
            } else if loggingStreak >= 2 {
                Label("Day \(loggingStreak) of logging in a row", systemImage: "leaf")
                    .foregroundStyle(Theme.green)
            } else {
                Label("Log anything to start a streak", systemImage: "leaf")
            }
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(Theme.soft)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentTransition(.opacity)
        .accessibilityIdentifier("nextUp")
    }

    private func siteText(_ due: Date) -> String? {
        let calendar = Calendar.current
        if calendar.isDateInToday(due) || due < now { return String(localized: "Site change due today") }
        if calendar.isDateInTomorrow(due) { return String(localized: "Site change due tomorrow") }
        return nil
    }
}

/// Small chips for the streaks worth noticing. Missing a day is a fresh
/// start, never a red mark.
struct StreakChips: View {
    let streaks: Streaks.Value

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                chip(
                    value: streaks.logging,
                    unit: streaks.logging == 1 ? String(localized: "day logging") : String(localized: "days logging"),
                    symbol: "flame",
                    empty: String(localized: "Fresh start today")
                )
                if streaks.daysWithoutUrgentLow > 0 {
                    chip(
                        value: streaks.daysWithoutUrgentLow,
                        unit: streaks.daysWithoutUrgentLow == 1 ? String(localized: "day, no urgent lows") : String(localized: "days, no urgent lows"),
                        symbol: "shield.lefthalf.filled",
                        empty: ""
                    )
                }
                if streaks.sitesOnTime > 0 {
                    chip(
                        value: streaks.sitesOnTime,
                        unit: streaks.sitesOnTime == 1 ? String(localized: "site changed on time") : String(localized: "sites changed on time"),
                        symbol: "arrow.triangle.2.circlepath",
                        empty: ""
                    )
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .accessibilityIdentifier("streakChips")
    }

    private func chip(value: Int, unit: String, symbol: String, empty: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .foregroundStyle(Theme.green)
                .symbolVariant(value > 0 ? .fill : .none)
            if value > 0 {
                Text("\(value)")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .contentTransition(.numericText(value: Double(value)))
                Text(unit)
                    .font(.subheadline)
            } else {
                Text(empty)
                    .font(.subheadline)
            }
        }
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.card, in: .capsule)
        .overlay(Capsule().strokeBorder(Theme.rule))
        .accessibilityElement(children: .combine)
    }
}

/// How the night went, shown in the morning.
struct NightCard: View {
    @Environment(SettingsStore.self) private var settings
    let night: Story.Night

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: night.lows == 0 ? "moon.stars.fill" : "moon.fill")
                .font(.title2)
                .foregroundStyle(night.lows == 0 ? Theme.green : Theme.amber)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Last night")
                    .friendlyLabel()
                Text(Story.sentence(for: night, glucose: settings.formattedGlucose))
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .card()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("nightCard")
    }
}

/// The day in a sentence or two. Shows yesterday in the morning and today
/// from late afternoon.
struct DayStoryCard: View {
    @Environment(SettingsStore.self) private var settings
    let title: String
    let day: Story.Day
    var onOpenRecap: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: "text.book.closed")
                    .friendlyLabel()
                Spacer()
                if let onOpenRecap {
                    Button("Your Week", action: onOpenRecap)
                        .font(.subheadline.weight(.semibold))
                        .accessibilityIdentifier("openWeeklyRecap")
                }
            }
            Text(Story.sentence(for: day, glucose: settings.formattedGlucose))
                .font(.body)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            InRangeBar(percent: day.inRangePercent)
        }
        .card()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("dayStory")
    }
}

/// A thin bar filled to the share of readings in range.
struct InRangeBar: View {
    let percent: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = 0.0

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.rule)
                Capsule().fill(Theme.green)
                    .frame(width: proxy.size.width * shown / 100)
            }
        }
        .frame(height: 8)
        .onAppear {
            if reduceMotion { shown = percent } else { withAnimation(.smooth(duration: 0.8).delay(0.1)) { shown = percent } }
        }
        .onChange(of: percent) { _, value in withAnimation(.smooth) { shown = value } }
        .accessibilityLabel("\(Int(percent.rounded())) percent in range")
    }
}
