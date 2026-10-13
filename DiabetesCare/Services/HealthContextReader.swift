//
//  HealthContextReader.swift
//  DiabetesCare
//
//  Optional context from Apple Health: steps, workouts, sleep and cycle
//  days, read only after the person turns it on in Trends. Used to put the
//  glucose picture next to the rest of the day ("lower nights after
//  workouts"). Read-only, stays on the phone.
//

import Foundation
import HealthKit
import OSLog

/// What Health says about one calendar day.
nonisolated struct DayContext: Equatable, Sendable {
    var day: Date
    var steps: Double = 0
    var workoutMinutes: Double = 0
    /// Sleep that ended on this day's morning.
    var sleepHours: Double = 0
    var period = false
}

nonisolated enum HealthContextInsights {
    struct Finding: Equatable, Sendable {
        var title: String
        var detail: String
    }

    /// Average glucose from midnight to 6 a.m. after days with a workout of
    /// 20+ minutes, against nights after days without. Needs 2 of each.
    static func workoutNights(days: [DayContext], samples: [GlucoseSample], calendar: Calendar = .current) -> (after: Double, other: Double)? {
        var after: [GlucoseSample] = []
        var other: [GlucoseSample] = []
        var afterCount = 0, otherCount = 0
        for context in days {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: context.day) else { continue }
            let night = DateInterval(start: nextDay, duration: 6 * 3600)
            let readings = samples.filter { night.contains($0.date) }
            guard readings.count >= 3 else { continue }
            if context.workoutMinutes >= 20 {
                after += readings; afterCount += 1
            } else {
                other += readings; otherCount += 1
            }
        }
        guard afterCount >= 2, otherCount >= 2 else { return nil }
        return (GlucoseCalculator.calculateAverage(samples: after), GlucoseCalculator.calculateAverage(samples: other))
    }

    /// Average glucose on cycle days against other days. Needs 2 of each.
    static func periodDays(days: [DayContext], samples: [GlucoseSample], calendar: Calendar = .current) -> (period: Double, other: Double)? {
        let periodDays = Set(days.filter(\.period).map { calendar.startOfDay(for: $0.day) })
        let byDay = Dictionary(grouping: samples) { calendar.startOfDay(for: $0.date) }
        let on = byDay.filter { periodDays.contains($0.key) }
        let off = byDay.filter { !periodDays.contains($0.key) }
        guard on.count >= 2, off.count >= 2 else { return nil }
        return (GlucoseCalculator.calculateAverage(samples: on.flatMap(\.value)),
                GlucoseCalculator.calculateAverage(samples: off.flatMap(\.value)))
    }

    /// Plain-language findings, only where the difference is worth saying.
    static func findings(days: [DayContext], samples: [GlucoseSample], format: (Double) -> String) -> [Finding] {
        var results: [Finding] = []
        if let nights = workoutNights(days: days, samples: samples), abs(nights.after - nights.other) >= 10 {
            let lower = nights.after < nights.other
            results.append(Finding(
                title: lower ? String(localized: "Lower nights after workouts") : String(localized: "Higher nights after workouts"),
                detail: String(localized: "Overnight average \(format(nights.after)) after a workout day, \(format(nights.other)) otherwise. Worth mentioning to your care team.")
            ))
        }
        if let period = periodDays(days: days, samples: samples), abs(period.period - period.other) >= 10 {
            let higher = period.period > period.other
            results.append(Finding(
                title: higher ? String(localized: "Higher on period days") : String(localized: "Lower on period days"),
                detail: String(localized: "Average \(format(period.period)) on period days, \(format(period.other)) on other days.")
            ))
        }
        let sleepDays = days.filter { $0.sleepHours > 0 }
        if sleepDays.count >= 3 {
            let average = sleepDays.reduce(0) { $0 + $1.sleepHours } / Double(sleepDays.count)
            results.append(Finding(
                title: String(localized: "Sleep"),
                detail: String(localized: "About \(average.formatted(.number.precision(.fractionLength(1)))) hours a night on average.")
            ))
        }
        return results
    }
}

/// Nonisolated: HealthKit calls back on its own queues.
nonisolated final class HealthContextReader: Sendable {
    static let shared = HealthContextReader()

    private let store = HKHealthStore()

    private let types: Set<HKObjectType> = [
        HKQuantityType(.stepCount),
        HKObjectType.workoutType(),
        HKCategoryType(.sleepAnalysis),
        HKCategoryType(.menstrualFlow),
    ]

    /// Shows the Health sheet for the context types. Health doesn't say
    /// what was allowed; reads just come back empty if not.
    func requestAccess() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: types)
        } catch {
            Log.health.error("Context authorization failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// One `DayContext` per calendar day in `range`, oldest first.
    func days(in range: DateInterval, calendar: Calendar = .current) async -> [DayContext] {
        guard HKHealthStore.isHealthDataAvailable() else { return [] }
        let start = calendar.startOfDay(for: range.start)
        var byDay: [Date: DayContext] = [:]
        var day = start
        while day <= range.end {
            byDay[day] = DayContext(day: day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        async let steps = dailySteps(from: start, to: range.end)
        async let workouts = samples(HKObjectType.workoutType(), from: start, to: range.end)
        async let sleep = samples(HKCategoryType(.sleepAnalysis), from: start.addingTimeInterval(-86_400), to: range.end)
        async let flow = samples(HKCategoryType(.menstrualFlow), from: start, to: range.end)

        for (date, count) in await steps {
            byDay[calendar.startOfDay(for: date)]?.steps = count
        }
        for workout in await workouts {
            byDay[calendar.startOfDay(for: workout.startDate)]?.workoutMinutes += workout.endDate.timeIntervalSince(workout.startDate) / 60
        }
        let asleep = Set(HKCategoryValueSleepAnalysis.allAsleepValues.map(\.rawValue))
        for case let sample as HKCategorySample in await sleep where asleep.contains(sample.value) {
            byDay[calendar.startOfDay(for: sample.endDate)]?.sleepHours += sample.endDate.timeIntervalSince(sample.startDate) / 3600
        }
        for case let sample as HKCategorySample in await flow where sample.value != HKCategoryValueVaginalBleeding.none.rawValue {
            byDay[calendar.startOfDay(for: sample.startDate)]?.period = true
        }
        return byDay.values.sorted { $0.day < $1.day }
    }

    private func samples(_ type: HKSampleType, from start: Date, to end: Date) async -> [HKSample] {
        await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error { Log.health.error("Context read failed: \(error.localizedDescription, privacy: .public)") }
                continuation.resume(returning: samples ?? [])
            }
            store.execute(query)
        }
    }

    private func dailySteps(from start: Date, to end: Date) async -> [(Date, Double)] {
        await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: HKQuantityType(.stepCount),
                quantitySamplePredicate: HKQuery.predicateForSamples(withStart: start, end: end),
                options: .cumulativeSum,
                anchorDate: start,
                intervalComponents: DateComponents(day: 1)
            )
            query.initialResultsHandler = { _, collection, _ in
                var result: [(Date, Double)] = []
                collection?.enumerateStatistics(from: start, to: end) { statistics, _ in
                    if let sum = statistics.sumQuantity() {
                        result.append((statistics.startDate, sum.doubleValue(for: .count())))
                    }
                }
                continuation.resume(returning: result)
            }
            store.execute(query)
        }
    }
}
