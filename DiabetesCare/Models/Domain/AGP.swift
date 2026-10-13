//
//  AGP.swift
//  DiabetesCare
//
//  The ambulatory glucose profile: every day folded onto one 24-hour
//  clock, with the median and the 25–75% and 5–95% bands. It's the view
//  clinics use for CGM data, so patterns by time of day stand out.
//  Also: what each meal did to glucose afterward.
//

import Foundation

nonisolated enum AGP {
    struct Bucket: Equatable, Identifiable, Sendable {
        /// Minutes after midnight at the bucket's middle.
        var minute: Int
        var p5: Double
        var p25: Double
        var median: Double
        var p75: Double
        var p95: Double
        var count: Int
        var id: Int { minute }
    }

    static let bucketMinutes = 30

    /// One bucket per half hour that has enough readings. Needs readings on
    /// at least `minimumDays` different days to mean anything.
    static func profile(samples: [GlucoseSample], minimumDays: Int = 5, minimumPerBucket: Int = 5, calendar: Calendar = .current) -> [Bucket] {
        let days = Set(samples.map { calendar.startOfDay(for: $0.date) })
        guard days.count >= minimumDays else { return [] }
        var buckets: [Int: [Double]] = [:]
        for sample in samples {
            let parts = calendar.dateComponents([.hour, .minute], from: sample.date)
            let minute = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
            buckets[minute / bucketMinutes, default: []].append(sample.mgdl)
        }
        return buckets.keys.sorted().compactMap { index in
            let values = buckets[index, default: []].sorted()
            guard values.count >= minimumPerBucket else { return nil }
            return Bucket(
                minute: index * bucketMinutes + bucketMinutes / 2,
                p5: percentile(values, 0.05),
                p25: percentile(values, 0.25),
                median: percentile(values, 0.5),
                p75: percentile(values, 0.75),
                p95: percentile(values, 0.95),
                count: values.count
            )
        }
    }

    /// Linear-interpolated percentile of sorted values.
    static func percentile(_ sorted: [Double], _ p: Double) -> Double {
        guard !sorted.isEmpty else { return 0 }
        let position = p * Double(sorted.count - 1)
        let lower = Int(position.rounded(.down))
        let upper = min(lower + 1, sorted.count - 1)
        let fraction = position - Double(lower)
        return sorted[lower] + (sorted[upper] - sorted[lower]) * fraction
    }

    /// The time of day with the highest median, and the lowest.
    static func extremes(_ buckets: [Bucket]) -> (highest: Bucket, lowest: Bucket)? {
        guard let high = buckets.max(by: { $0.median < $1.median }),
              let low = buckets.min(by: { $0.median < $1.median }) else { return nil }
        return (high, low)
    }
}

nonisolated enum MealImpact {
    struct Meal: Equatable, Identifiable, Sendable {
        var id: Date { time }
        var time: Date
        var name: String
        var carbs: Double
        var before: Double
        var peak: Double
        /// About two hours later (90–150 minutes), if there's a reading.
        var twoHours: Double?
        var rise: Double { peak - before }
    }

    struct Food: Equatable, Identifiable, Sendable {
        var id: String { name }
        var name: String
        var meals: Int
        var averageRise: Double
        var averageCarbs: Double
    }

    struct Entry: Sendable {
        var time: Date
        var name: String
        var carbs: Double
    }

    /// Needs a reading within 30 minutes before the meal and at least two in
    /// the three hours after. Meals followed by another meal within 90
    /// minutes are skipped, since the rise can't be told apart.
    static func meals(entries: [Entry], samples: [GlucoseSample]) -> [Meal] {
        let sorted = samples.sorted { $0.date < $1.date }
        let times = entries.map(\.time).sorted()
        return entries.compactMap { entry in
            if times.contains(where: { $0 > entry.time && $0.timeIntervalSince(entry.time) < 90 * 60 }) { return nil }
            guard let before = sorted.last(where: { $0.date <= entry.time && entry.time.timeIntervalSince($0.date) <= 30 * 60 }) else { return nil }
            let after = sorted.filter { $0.date > entry.time && $0.date.timeIntervalSince(entry.time) <= 3 * 3600 }
            guard after.count >= 2, let peak = after.map(\.mgdl).max() else { return nil }
            let twoHours = after
                .filter { (90 * 60...150 * 60).contains($0.date.timeIntervalSince(entry.time)) }
                .min { abs($0.date.timeIntervalSince(entry.time) - 7200) < abs($1.date.timeIntervalSince(entry.time) - 7200) }?
                .mgdl
            return Meal(time: entry.time, name: entry.name, carbs: entry.carbs, before: before.mgdl, peak: max(peak, before.mgdl), twoHours: twoHours)
        }
        .sorted { $0.time > $1.time }
    }

    /// Meals grouped by name, for names eaten at least `minimum` times.
    static func foods(_ meals: [Meal], minimum: Int = 2) -> [Food] {
        Dictionary(grouping: meals) { $0.name.lowercased() }
            .compactMap { _, group in
                guard group.count >= minimum, let first = group.first else { return nil }
                return Food(
                    name: first.name,
                    meals: group.count,
                    averageRise: group.reduce(0) { $0 + $1.rise } / Double(group.count),
                    averageCarbs: group.reduce(0) { $0 + $1.carbs } / Double(group.count)
                )
            }
            .sorted { $0.averageRise > $1.averageRise }
    }
}
