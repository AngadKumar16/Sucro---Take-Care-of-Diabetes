//
//  ContextSections.swift
//  DiabetesCare
//
//  Trends sections that put glucose next to the rest of life: day tags
//  ("higher on sick days") and, when turned on, steps, workouts, sleep and
//  cycle days from Apple Health.
//

import Charts
import CoreData
import SwiftUI

/// Glucose on tagged days against untagged days.
struct TagInsightsSection: View {
    @Environment(SettingsStore.self) private var settings
    let comparisons: [TagInsights.Comparison]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeader("Your Days")
            VStack(alignment: .leading, spacing: 12) {
                if comparisons.isEmpty {
                    Text("Tag days on Today (sick, sports, stressed…). After a couple of each, you'll see how glucose compares.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.soft)
                } else {
                    ForEach(comparisons, id: \.tag) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item.tag.symbol)
                                .font(.title3)
                                .foregroundStyle(Theme.green)
                                .frame(width: 28)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(item.tag.name) days (\(item.days))")
                                    .font(.subheadline.weight(.semibold))
                                Text("Average \(settings.formattedGlucose(item.average)) vs \(settings.formattedGlucose(item.otherAverage)) on other days. \(Int(item.inRangePercent.rounded()))% in range vs \(Int(item.otherInRangePercent.rounded()))%.")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.soft)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .card()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tagInsights")
    }
}

/// Steps, workouts and sleep beside glucose, from Apple Health.
struct HealthContextSection: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.managedObjectContext) private var viewContext
    let range: TimeRange

    @State private var days: [DayContext] = []
    @State private var findings: [HealthContextInsights.Finding] = []
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeader("Activity & Sleep")
            Group {
                if !settings.healthContextEnabled {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("See steps, workouts, sleep and cycle days from Apple Health next to your glucose. Read only, and it stays on this phone.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.soft)
                            .fixedSize(horizontal: false, vertical: true)
                        Button("Connect Apple Health", systemImage: "heart.text.square") {
                            Task {
                                await HealthContextReader.shared.requestAccess()
                                settings.healthContextEnabled = true
                                await load()
                            }
                        }
                        .buttonStyle(.soft)
                        .accessibilityIdentifier("connectHealthContext")
                    }
                } else if days.allSatisfy({ $0.steps == 0 && $0.workoutMinutes == 0 && $0.sleepHours == 0 }) {
                    Text(isLoading ? "Reading Apple Health…" : "Nothing from Apple Health for this period yet. Steps, workouts and sleep from your phone or watch show up here.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.soft)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Chart(days, id: \.day) { day in
                            BarMark(x: .value("Day", day.day, unit: .day), y: .value("Steps", day.steps))
                                .foregroundStyle(Theme.green.opacity(day.workoutMinutes >= 20 ? 1 : 0.45))
                                .accessibilityLabel(day.day.formatted(.dateTime.weekday(.wide).month().day()))
                                .accessibilityValue("\(Int(day.steps)) steps, \(Int(day.workoutMinutes)) workout minutes, \(day.sleepHours.formatted(.number.precision(.fractionLength(1)))) hours of sleep")
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { _ in
                                AxisGridLine()
                                AxisValueLabel()
                            }
                        }
                        .frame(height: 120)
                        Text("Steps a day. Darker bars had a workout of 20 minutes or more.")
                            .font(.caption)
                            .foregroundStyle(Theme.soft)
                        ForEach(findings, id: \.title) { finding in
                            InsightCard(title: finding.title, description: finding.detail, type: .info)
                                .padding(-12)
                                .padding(.vertical, 6)
                        }
                    }
                }
            }
            .card()
        }
        .task(id: range) { await load() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("healthContext")
    }

    private func load() async {
        guard settings.healthContextEnabled else { return }
        isLoading = true
        defer { isLoading = false }
        let interval = DateInterval(start: Date().addingTimeInterval(-Double(max(range.days, 14)) * 86_400), end: Date())
        let loaded = await HealthContextReader.shared.days(in: interval)
        days = loaded.filter { $0.day >= Calendar.current.startOfDay(for: range.interval().start) || range.days < 7 }
        let samples = DataService.shared.fetchGlucoseReadings(context: viewContext, in: interval).compactMap(\.sample)
        findings = HealthContextInsights.findings(days: loaded, samples: samples, format: settings.formattedGlucose)
    }
}
