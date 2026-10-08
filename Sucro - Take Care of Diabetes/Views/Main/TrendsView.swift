//
//  TrendsView.swift
//  Sucro - Take Care of Diabetes
//
//  Glucose over a chosen range: summary numbers, a chart you can scrub,
//  what stands out, and averages by weekday.
//

import SwiftUI
import CoreData
import Charts

struct TrendsView: View {
    @Environment(MonitorViewModel.self) private var monitor
    @Environment(InsightsViewModel.self) private var insights
    @Environment(SettingsStore.self) private var settings

    @State private var range: TimeRange = .day

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("Time Range", selection: $range) {
                    ForEach(TimeRange.trends, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)

                if monitor.trendData.isEmpty {
                    ContentUnavailableView {
                        Label("No Readings", systemImage: "chart.xyaxis.line")
                    } description: {
                        Text("Glucose you log in this period will show up here.")
                    }
                    .card()
                } else {
                    statTiles
                    GlucoseTrendChart(points: monitor.trendData, range: range)
                        .card()
                }

                insightsSection
                weekdaySection
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Trends")
        .onAppear {
            range = monitor.timeRange
            refresh()
        }
        .onChange(of: range) { _, range in
            monitor.timeRange = range
            insights.timeRange = range
        }
        .refreshable { refresh() }
    }

    private func refresh() {
        insights.timeRange = range
        monitor.fetchDataForTimeRange()
        insights.fetchInsights()
    }

    private var statTiles: some View {
        HStack(spacing: 12) {
            StatTile(title: "Average", value: settings.glucoseValueString(monitor.averageGlucose), unit: settings.glucoseUnit)
            StatTile(title: "In Range", value: monitor.timeInRange.formatted(.number.precision(.fractionLength(0))), unit: "%")
            StatTile(
                title: "Low – High",
                value: "\(settings.glucoseValueString(monitor.glucoseRange.min))–\(settings.glucoseValueString(monitor.glucoseRange.max))",
                unit: settings.glucoseUnit
            )
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeader("What Stands Out")
            VStack(spacing: 0) {
                ForEach(Array(insights.generatedInsights.enumerated()), id: \.element.id) { index, insight in
                    if index > 0 { Divider().padding(.leading, 48) }
                    InsightCard(title: insight.title, description: insight.description, type: insight.type)
                }
            }
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
        }
    }

    private var weekdaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeader("Weekly Patterns")
            Group {
                if insights.weeklyPatterns.isEmpty {
                    Text("No readings in the past week.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Average glucose by day, past 7 days")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Chart(insights.weeklyPatterns) { pattern in
                            BarMark(
                                x: .value("Day", shortWeekday(pattern.weekdayIndex)),
                                y: .value("Average", settings.displayGlucose(pattern.average)),
                                width: .ratio(0.6)
                            )
                            .foregroundStyle(settings.zone(for: pattern.average).color.gradient)
                            .cornerRadius(4)
                            .annotation(position: .top) {
                                Text(settings.glucoseValueString(pattern.average))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityLabel(pattern.name)
                            .accessibilityValue(settings.formattedGlucose(pattern.average))
                        }
                        .chartXScale(domain: Calendar.current.shortWeekdaySymbols)
                        .chartYAxis(.hidden)
                        .frame(height: 140)
                    }
                }
            }
            .card()
        }
    }
}

private func shortWeekday(_ weekday: Int) -> String {
    let symbols = Calendar.current.shortWeekdaySymbols
    return symbols.indices.contains(weekday - 1) ? symbols[weekday - 1] : "\(weekday)"
}

/// One number with a caption, for the row at the top of Trends.
struct StatTile: View {
    let title: String
    let value: String
    let unit: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let unit {
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .card(padding: 12)
        .accessibilityElement(children: .combine)
    }
}

/// Glucose over the chosen range on top of the target band. Drag across it
/// to read a value.
struct GlucoseTrendChart: View {
    @Environment(SettingsStore.self) private var settings
    let points: [MonitorViewModel.GlucoseTrendPoint]
    let range: TimeRange

    @State private var selectedDate: Date?

    private var selectedPoint: MonitorViewModel.GlucoseTrendPoint? {
        guard let selectedDate else { return nil }
        return points.min { abs($0.timestamp.timeIntervalSince(selectedDate)) < abs($1.timestamp.timeIntervalSince(selectedDate)) }
    }

    var body: some View {
        let interval = range.interval()
        let highest = points.map(\.value).max() ?? 0

        VStack(alignment: .leading, spacing: 8) {
            Text("Glucose")
                .font(.headline)

            Chart {
                RectangleMark(
                    xStart: .value("Start", interval.start),
                    xEnd: .value("End", interval.end),
                    yStart: .value("Target low", settings.displayGlucose(settings.targetLow)),
                    yEnd: .value("Target high", settings.displayGlucose(settings.targetHigh))
                )
                .foregroundStyle(.green.opacity(0.12))

                ForEach(points) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Glucose", settings.displayGlucose(point.value))
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.monotone)

                    if range == .day {
                        PointMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Glucose", settings.displayGlucose(point.value))
                        )
                        .foregroundStyle(settings.zone(for: point.value).color)
                        .symbolSize(24)
                    }
                }

                if let selectedPoint {
                    RuleMark(x: .value("Selected", selectedPoint.timestamp))
                        .foregroundStyle(.secondary.opacity(0.5))
                        .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                            VStack(spacing: 0) {
                                Text(settings.formattedGlucose(selectedPoint.value))
                                    .font(.caption.bold())
                                Text(selectedPoint.timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(6)
                            .background(.regularMaterial, in: .rect(cornerRadius: 8))
                        }
                    PointMark(
                        x: .value("Selected", selectedPoint.timestamp),
                        y: .value("Glucose", settings.displayGlucose(selectedPoint.value))
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(80)
                }
            }
            .chartXScale(domain: interval.start...interval.end, range: .plotDimension(endPadding: 28))
            .chartYScale(domain: settings.displayGlucose(40)...settings.displayGlucose(max(300, highest + 20)))
            .chartXSelection(value: $selectedDate)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: axisFormat)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 220)
        }
    }

    private var axisFormat: Date.FormatStyle {
        switch range {
        case .day: return .dateTime.hour()
        case .week: return .dateTime.weekday(.abbreviated)
        case .month, .quarter, .year: return .dateTime.month(.abbreviated).day()
        }
    }
}

struct InsightCard: View {
    let title: String
    let description: String
    let type: InsightType

    enum InsightType {
        case positive, warning, info

        var color: Color {
            switch self {
            case .positive: return .green
            case .warning: return .orange
            case .info: return .blue
            }
        }

        var icon: String {
            switch self {
            case .positive: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: type.icon)
                .foregroundStyle(type.color)
                .font(.title3)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    NavigationStack {
        TrendsView()
    }
    .environment(MonitorViewModel(context: context))
    .environment(InsightsViewModel(context: context))
    .environment(SettingsStore())
}
