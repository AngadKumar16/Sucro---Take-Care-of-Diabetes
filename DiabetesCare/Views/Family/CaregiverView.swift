//
//  CaregiverView.swift
//  DiabetesCare
//
//  What a parent sees for someone they follow: the latest reading in that
//  person's own ranges, the last 12 hours, today in numbers, what was
//  logged, and how far along their path they are. Read only.
//

import Charts
import CoreData
import SwiftUI

struct CaregiverView: View {
    let person: FamilyPerson
    let store: PersistenceController
    /// The preview says so, instead of "from iCloud".
    var isPreview = false

    @Environment(SettingsStore.self) private var settings
    @State private var model = CaregiverModel()

    private var profile: FamilyProfile? { person.profile }
    private var thresholds: GlucoseThresholds { profile?.thresholds ?? .standard }

    var body: some View {
        ScrollView {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                VStack(alignment: .leading, spacing: 16) {
                    if isPreview { previewNote }
                    latest(now: context.date)
                    chart(now: context.date)
                    today
                    recent
                    if let profile { path(profile) }
                    Text(footer)
                        .font(.footnote)
                        .foregroundStyle(Theme.soft)
                }
                .padding()
                .frame(maxWidth: 720, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .fontDesign(.rounded)
        .instrumentBackground()
        .navigationTitle(person.displayName)
        .onAppear { model.load(from: store.container.viewContext, thresholds: thresholds) }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: store.container.viewContext)) { _ in
            model.load(from: store.container.viewContext, thresholds: thresholds)
        }
    }

    private var footer: String {
        if isPreview { return String(localized: "Preview built on this phone. Nothing was sent.") }
        #if DEBUG
        if person.id == DemoData.demoPersonID { return String(localized: "Sample data for a demo. Nothing came from another phone.") }
        #endif
        return String(localized: "Read only. Comes from \(person.displayName)'s phone through iCloud.")
    }

    private var previewNote: some View {
        Label("This is what your family sees on their phone.", systemImage: "eye")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.green)
            .softPanel(border: Theme.green)
    }

    @ViewBuilder
    private func latest(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let profile {
                    Label(profile.stage.title, systemImage: profile.stage.symbol)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.green.opacity(0.12), in: .capsule)
                        .foregroundStyle(Theme.green)
                }
                Spacer()
                if let sync = person.lastSync {
                    Text("Updated \(sync, format: .relative(presentation: .named))")
                        .font(.caption)
                        .foregroundStyle(Theme.soft)
                }
            }
            if let reading = model.latest {
                let zone = thresholds.zone(for: reading.mgdl)
                let age = now.timeIntervalSince(reading.date)
                let stale = age > 15 * 60
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(settings.glucoseValueString(reading.mgdl))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold).scaled(by: 1.6))
                        .monospacedDigit()
                        .foregroundStyle(stale ? Theme.soft : zone.color)
                    Text(settings.glucoseUnit)
                        .font(.headline)
                        .foregroundStyle(Theme.soft)
                    if let trend = model.trend, !stale {
                        Image(systemName: trend.icon)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(zone.color)
                            .accessibilityLabel(trend.rawValue.replacingOccurrences(of: "_", with: " "))
                    }
                }
                Label(stale ? String(localized: "Last reading \(Int(age / 60)) min ago") : zone.name,
                      systemImage: stale ? "clock" : zone.symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(stale ? Theme.soft : zone.color)
                Text(reading.date, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(Theme.soft)
            } else {
                Text("No glucose shared yet")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text("Readings show up here as soon as \(person.displayName) logs one or their CGM sends one.")
                    .foregroundStyle(Theme.soft)
            }
        }
        .softPanel()
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func chart(now: Date) -> some View {
        let start = now.addingTimeInterval(-12 * 3600)
        let points = model.samples.filter { $0.date >= start }
        if !points.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Last 12 Hours").friendlyLabel()
                Chart {
                    RectangleMark(
                        xStart: .value("Start", start),
                        xEnd: .value("End", now),
                        yStart: .value("Low", settings.displayGlucose(thresholds.targetLow)),
                        yEnd: .value("High", settings.displayGlucose(thresholds.targetHigh))
                    )
                    .foregroundStyle(Theme.green.opacity(0.10))
                    ForEach(points, id: \.date) { sample in
                        LineMark(x: .value("Time", sample.date), y: .value("Glucose", settings.displayGlucose(sample.mgdl)))
                            .foregroundStyle(Theme.ink.opacity(0.35))
                            .interpolationMethod(.monotone)
                        PointMark(x: .value("Time", sample.date), y: .value("Glucose", settings.displayGlucose(sample.mgdl)))
                            .foregroundStyle(thresholds.zone(for: sample.mgdl).color)
                            .symbolSize(points.count > 60 ? 10 : 30)
                    }
                }
                .chartXScale(domain: start...now)
                .frame(height: 180)
                .accessibilityLabel("Glucose over the last 12 hours")
            }
            .softPanel()
        }
    }

    private var today: some View {
        let stats = model.today
        return VStack(alignment: .leading, spacing: 12) {
            Text("Today").friendlyLabel()
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                GridRow {
                    figure(stats.inRangePercent.map { "\($0)%" } ?? "–", String(localized: "in range"), Theme.green)
                    figure("\(stats.lows)", stats.lows == 1 ? String(localized: "low") : String(localized: "lows"), Theme.vermilion)
                }
                GridRow {
                    figure("\(Int(stats.carbs)) g", String(localized: "carbs"), Theme.amber)
                    figure("\(stats.insulin.formatted(.number.precision(.fractionLength(0...1)))) U", String(localized: "insulin"), Theme.indigo)
                }
            }
        }
        .softPanel()
    }

    private func figure(_ value: String, _ label: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(tint)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.soft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var recent: some View {
        if !model.events.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Logged Today").friendlyLabel()
                ForEach(model.events.prefix(12)) { event in
                    HStack(spacing: 12) {
                        Image(systemName: event.icon)
                            .foregroundStyle(event.color)
                            .frame(width: 32, height: 32)
                            .background(event.color.opacity(0.12), in: .circle)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title).font(.subheadline.weight(.semibold))
                            if let subtitle = event.subtitle {
                                Text(subtitle).font(.caption).foregroundStyle(Theme.soft)
                            }
                        }
                        Spacer()
                        Text(event.timestamp, format: .dateTime.hour().minute())
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Theme.soft)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .softPanel()
        }
    }

    private func path(_ profile: FamilyProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Their Path").friendlyLabel()
            StageLadder(current: profile.stage)
            Text("Learned \(profile.completedSkills.count) of \(Skill.allCases.count) skills")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.ink)
            if profile.stage.isReadyToMoveUp(completed: Set(profile.completedSkills)), let next = profile.stage.next {
                Label("Ready to move up to \(next.title). You can approve it on their phone.", systemImage: "star.fill")
                    .font(.subheadline)
                    .foregroundStyle(Theme.green)
            }
        }
        .softPanel()
    }
}

/// Reads a followed person's store for the caregiver screen.
@MainActor
@Observable
final class CaregiverModel {
    struct Today: Equatable {
        var inRangePercent: Int?
        var lows = 0
        var carbs: Double = 0
        var insulin: Double = 0
    }

    private(set) var samples: [GlucoseSample] = []
    private(set) var latest: GlucoseSample?
    private(set) var trend: GlucoseTrend?
    private(set) var today = Today()
    private(set) var events: [TimelineEvent] = []

    func load(from context: NSManagedObjectContext, thresholds: GlucoseThresholds, now: Date = Date()) {
        let data = DataService.shared
        let dayStart = Calendar.current.startOfDay(for: now)
        let since = min(dayStart, now.addingTimeInterval(-12 * 3600))
        let readings = data.fetchGlucoseReadings(context: context, in: DateInterval(start: since, end: now))
        samples = readings.compactMap(\.sample).sorted { $0.date < $1.date }
        latest = samples.last
        trend = readings.max { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }
            .flatMap { GlucoseTrend(stored: $0.trend) }

        let todays = samples.filter { $0.date >= dayStart }
        let interval = DateInterval(start: dayStart, end: now)
        today = Today(
            inRangePercent: todays.isEmpty ? nil : Int((Double(todays.filter { thresholds.zone(for: $0.mgdl) == .inRange }.count) / Double(todays.count) * 100).rounded()),
            lows: Self.lowEpisodes(todays, thresholds: thresholds),
            carbs: data.fetchCarbEntries(context: context, in: interval).reduce(0) { $0 + $1.grams },
            insulin: data.fetchInsulinEntries(context: context, in: interval).reduce(0) { $0 + $1.units }
        )
        events = TimelineService.shared.buildTimeline(context: context, hoursBack: max(1, Int(now.timeIntervalSince(dayStart) / 3600) + 1), limited: false)
    }

    /// Runs of low readings count once.
    static func lowEpisodes(_ samples: [GlucoseSample], thresholds: GlucoseThresholds) -> Int {
        var count = 0
        var inLow = false
        for sample in samples.sorted(by: { $0.date < $1.date }) {
            let low = thresholds.zone(for: sample.mgdl).isLow
            if low && !inLow { count += 1 }
            inLow = low
        }
        return count
    }
}
