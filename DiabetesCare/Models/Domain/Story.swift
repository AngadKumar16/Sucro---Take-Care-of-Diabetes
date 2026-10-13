//
//  Story.swift
//  DiabetesCare
//
//  Plain-language summaries of the log: how a day went, how the night
//  went, how the week compared with the one before, and the streaks worth
//  celebrating. Pure math on samples, so it's easy to test. Nothing here
//  gives advice; it only describes what was logged.
//

import Foundation

nonisolated enum Story {
    /// Two readings further apart than this don't make one stretch.
    static let maxGap: TimeInterval = 30 * 60

    // MARK: - A day

    struct Day: Equatable, Sendable {
        var interval: DateInterval
        var readingCount: Int
        var average: Double
        var lowest: Double
        var highest: Double
        var inRangePercent: Double
        /// Hours in range, from the stretches readings cover.
        var inRangeHours: Double
        /// The longest unbroken run of in-range readings.
        var bestStretch: DateInterval?
        var lows: Int
        /// Lows with carbs logged within 20 minutes.
        var lowsTreated: Int
    }

    static func day(samples: [GlucoseSample], carbTimes: [Date], thresholds: GlucoseThresholds, in interval: DateInterval) -> Day? {
        let inDay = samples.filter { interval.contains($0.date) }.sorted { $0.date < $1.date }
        guard !inDay.isEmpty else { return nil }
        let values: [Double] = inDay.map { $0.mgdl }
        let isInRange: (Double) -> Bool = { thresholds.zone(for: $0) == .inRange }
        let inRangeCount = values.count(where: isInRange)
        let runs = stretches(inDay, where: isInRange)
        let runSeconds: TimeInterval = runs.reduce(0) { $0 + $1.duration }
        let episodes = lowEpisodes(inDay, thresholds: thresholds)
        let treated = episodes.count { start in
            carbTimes.contains { time in
                time >= start.addingTimeInterval(-5 * 60) && time.timeIntervalSince(start) <= 20 * 60
            }
        }
        let total = Double(values.count)
        return Day(
            interval: interval,
            readingCount: values.count,
            average: values.reduce(0, +) / total,
            lowest: values.min() ?? 0,
            highest: values.max() ?? 0,
            inRangePercent: Double(inRangeCount) / total * 100,
            inRangeHours: runSeconds / 3600,
            bestStretch: runs.max { $0.duration < $1.duration },
            lows: episodes.count,
            lowsTreated: treated
        )
    }

    /// Runs of consecutive readings matching `test`, with no gap over
    /// `maxGap`. A single reading is a run of zero length.
    static func stretches(_ sorted: [GlucoseSample], where test: (Double) -> Bool) -> [DateInterval] {
        var runs: [DateInterval] = []
        var start: Date?
        var last: Date?
        func close() {
            if let start, let last { runs.append(DateInterval(start: start, end: last)) }
            start = nil
            last = nil
        }
        for sample in sorted {
            guard test(sample.mgdl) else {
                close()
                continue
            }
            if let previous = last, sample.date.timeIntervalSince(previous) <= maxGap {
                last = sample.date
            } else {
                close()
                start = sample.date
                last = sample.date
            }
        }
        close()
        return runs
    }

    /// When each low began. Readings in the same low (no in-range reading
    /// between, under `maxGap` apart) count once.
    static func lowEpisodes(_ sorted: [GlucoseSample], thresholds: GlucoseThresholds) -> [Date] {
        var starts: [Date] = []
        var inLow = false
        var lastLow: Date?
        for sample in sorted {
            let low = thresholds.zone(for: sample.mgdl).isLow
            if low {
                if !inLow || (lastLow.map { sample.date.timeIntervalSince($0) > maxGap } ?? true) {
                    starts.append(sample.date)
                }
                inLow = true
                lastLow = sample.date
            } else {
                inLow = false
            }
        }
        return starts
    }

    /// One or two friendly sentences about the day.
    static func sentence(for day: Day, glucose: (Double) -> String) -> String {
        var parts: [String] = []
        let hours = day.inRangeHours
        if day.readingCount >= 12, hours >= 0.5 {
            parts.append(String(localized: "\(durationText(hours * 3600)) in range."))
        } else {
            parts.append(String(localized: "\(Int(day.inRangePercent.rounded()))% of readings in range."))
        }
        if let best = day.bestStretch, best.duration >= 60 * 60 {
            let from = best.start.formatted(date: .omitted, time: .shortened)
            let to = best.end.formatted(date: .omitted, time: .shortened)
            parts.append(String(localized: "Steadiest stretch \(from)–\(to)."))
        }
        switch (day.lows, day.lowsTreated) {
        case (0, _):
            parts.append(String(localized: "No lows."))
        case let (lows, treated) where treated == lows:
            parts.append(lows == 1 ? String(localized: "1 low, treated quickly.") : String(localized: "\(lows) lows, all treated quickly."))
        case let (lows, _):
            parts.append(lows == 1 ? String(localized: "1 low.") : String(localized: "\(lows) lows."))
        }
        parts.append(String(localized: "Range \(glucose(day.lowest))–\(glucose(day.highest))."))
        return parts.joined(separator: " ")
    }

    static func durationText(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated, maximumUnitCount: 2))
    }

    // MARK: - The night

    struct Night: Equatable, Sendable {
        var lowest: Double
        var highest: Double
        var lows: Int
        var readingCount: Int
        /// Little movement: under 60 mg/dL between lowest and highest.
        var isSteady: Bool { highest - lowest < 60 }
    }

    /// Midnight to 6 a.m. of the day `now` falls in.
    static func nightInterval(for now: Date, calendar: Calendar = .current) -> DateInterval {
        let start = calendar.startOfDay(for: now)
        return DateInterval(start: start, duration: 6 * 3600)
    }

    static func night(samples: [GlucoseSample], thresholds: GlucoseThresholds, now: Date, calendar: Calendar = .current) -> Night? {
        let interval = nightInterval(for: now, calendar: calendar)
        let readings = samples.filter { interval.contains($0.date) }.sorted { $0.date < $1.date }
        // A finger stick or two doesn't describe a night.
        guard readings.count >= 3 else { return nil }
        let values = readings.map(\.mgdl)
        return Night(
            lowest: values.min() ?? 0,
            highest: values.max() ?? 0,
            lows: lowEpisodes(readings, thresholds: thresholds).count,
            readingCount: readings.count
        )
    }

    static func sentence(for night: Night, glucose: (Double) -> String) -> String {
        let range = String(localized: "\(glucose(night.lowest))–\(glucose(night.highest))")
        let lows = night.lows == 0 ? String(localized: "no lows") : (night.lows == 1 ? String(localized: "1 low") : String(localized: "\(night.lows) lows"))
        return night.isSteady
            ? String(localized: "Steady night, \(range), \(lows).")
            : String(localized: "Night ranged \(range), \(lows).")
    }

    // MARK: - A week

    struct Week: Equatable, Sendable {
        var interval: DateInterval
        var inRangePercent: Double
        /// The week before, for comparison. `nil` without readings.
        var previousInRangePercent: Double?
        /// The day with the smallest spread of readings.
        var steadiestDay: Date?
        var loggedDays: Int
        var lows: Int
        var readingCount: Int
        var average: Double
    }

    /// The seven days ending `now`, compared with the seven before.
    static func week(samples: [GlucoseSample], loggedDates: [Date], thresholds: GlucoseThresholds, now: Date, calendar: Calendar = .current) -> Week? {
        let end = now
        let start = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)) ?? now
        let interval = DateInterval(start: start, end: max(start, end))
        let previous = DateInterval(start: start.addingTimeInterval(-7 * 86_400), end: start)
        let current = samples.filter { interval.contains($0.date) }.sorted { $0.date < $1.date }
        guard !current.isEmpty else { return nil }
        let before = samples.filter { previous.contains($0.date) && $0.date < start }

        func percent(_ s: [GlucoseSample]) -> Double {
            Double(s.count { thresholds.zone(for: $0.mgdl) == .inRange }) / Double(s.count) * 100
        }

        // Steadiest day: smallest standard deviation among days with enough readings.
        let byDay = Dictionary(grouping: current) { calendar.startOfDay(for: $0.date) }
        let steadiest = byDay
            .filter { $0.value.count >= 3 }
            .min { GlucoseCalculator.calculateStandardDeviation(samples: $0.value) < GlucoseCalculator.calculateStandardDeviation(samples: $1.value) }?
            .key

        let logged = Set(loggedDates.filter { interval.contains($0) }.map { calendar.startOfDay(for: $0) })
        return Week(
            interval: interval,
            inRangePercent: percent(current),
            previousInRangePercent: before.isEmpty ? nil : percent(before),
            steadiestDay: steadiest,
            loggedDays: logged.count,
            lows: lowEpisodes(current, thresholds: thresholds).count,
            readingCount: current.count,
            average: GlucoseCalculator.calculateAverage(samples: current)
        )
    }
}

// MARK: - Streaks

nonisolated enum Streaks {
    struct Value: Equatable, Sendable {
        /// Days in a row with something logged by hand.
        var logging = 0
        /// Days since the last urgent low, counted only over days with readings.
        var daysWithoutUrgentLow = 0
        /// Site changes in a row worn no longer than their rotation days.
        var sitesOnTime = 0
    }

    /// Streak lengths worth a small celebration.
    static let milestones = [3, 7, 14, 30, 60, 100, 200, 365]

    static func daysWithoutUrgentLow(samples: [GlucoseSample], thresholds: GlucoseThresholds, now: Date, calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: now)
        let readingDays = Set(samples.map { calendar.startOfDay(for: $0.date) })
        guard let first = readingDays.min() else { return 0 }
        let lastUrgent = samples.filter { $0.mgdl < thresholds.urgentLow }.map(\.date).max()
        // Counted from the day after the last urgent low (or the first day
        // with readings), through today.
        let from = lastUrgent.map { calendar.startOfDay(for: $0).addingTimeInterval(86_400) } ?? first
        guard from <= today else { return 0 }
        return (calendar.dateComponents([.day], from: from, to: today).day ?? 0) + 1
    }

    static func sitesOnTime(_ changes: [SiteRotation.Change], now: Date) -> Int {
        // Only finished changes count; the one in use hasn't been judged yet.
        let finished = SiteRotation.wear(changes).filter { $0.endedAt != nil }
        var count = 0
        for wear in finished {
            if wear.wasOverdue(now: now) { break }
            count += 1
        }
        return count
    }

    /// The milestone just reached, if `value` is one and it's newer than the
    /// last one celebrated.
    static func newMilestone(value: Int, lastCelebrated: Int) -> Int? {
        guard milestones.contains(value), value > lastCelebrated else { return nil }
        return value
    }
}

// MARK: - Growth

/// How grown the sprout on Your Path is: from a seed to a flower, fed by
/// skills learned and logging streaks.
nonisolated enum SproutGrowth: Int, CaseIterable, Comparable, Sendable {
    case seed, sprout, seedling, plant, bud, flower

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    static func level(skills: Int, streak: Int) -> SproutGrowth {
        let streakPoints = streak >= 14 ? 3 : streak >= 7 ? 2 : streak >= 3 ? 1 : 0
        let points = skills + streakPoints
        let raw = switch points {
        case 0: 0
        case 1...2: 1
        case 3...4: 2
        case 5...6: 3
        case 7...8: 4
        default: 5
        }
        return SproutGrowth(rawValue: raw) ?? .seed
    }

    var name: String {
        switch self {
        case .seed: String(localized: "Seed")
        case .sprout: String(localized: "Sprout")
        case .seedling: String(localized: "Seedling")
        case .plant: String(localized: "Little Plant")
        case .bud: String(localized: "Budding")
        case .flower: String(localized: "In Bloom")
        }
    }
}
