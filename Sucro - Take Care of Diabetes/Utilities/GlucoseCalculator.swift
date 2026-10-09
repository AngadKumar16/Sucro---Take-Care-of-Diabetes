//
//  GlucoseCalculator.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//
//  Pure glucose and insulin math. Everything here takes plain values so it
//  can be unit tested without Core Data.
//

import Foundation

nonisolated enum GlucoseCalculator {

    // MARK: - Insulin on Board (IOB)

    /// Time to peak activity for rapid-acting insulin, in minutes. 75 min is
    /// the adult rapid-acting curve used by Loop and OpenAPS.
    static let insulinPeakMinutes: Double = 75

    /// Fraction of a dose still active `minutes` after it was given, using the
    /// exponential insulin activity curve from Loop/OpenAPS
    /// (https://github.com/LoopKit/Loop/issues/388). Returns 1 at the moment of
    /// the dose and 0 once `actionHours` have passed.
    static func insulinRemainingFraction(minutesSinceDose t: Double, actionHours: Double) -> Double {
        let td = actionHours * 60
        guard t > 0 else { return 1 }
        guard t < td else { return 0 }

        // The curve needs the peak before the halfway point.
        let tp = min(insulinPeakMinutes, td / 2 - 1)
        let tau = tp * (1 - tp / td) / (1 - 2 * tp / td)
        let a = 2 * tau / td
        let s = 1 / (1 - a + (1 + a) * exp(-td / tau))
        let remaining = 1 - s * (1 - a) * ((t * t / (tau * td * (1 - a)) - t / tau - 1) * exp(-t / tau) + 1)
        return min(1, max(0, remaining))
    }

    /// Estimated rapid-acting insulin still working at `now`. Basal,
    /// intermediate, mixed and unknown doses are ignored, as are doses logged
    /// in the future. This is a display estimate, not dosing advice.
    static func insulinOnBoard(doses: [InsulinDose], at now: Date = Date(), actionHours: Double) -> Double {
        doses.reduce(0) { total, dose in
            guard dose.type?.isRapidActing == true, dose.date <= now else { return total }
            let minutes = now.timeIntervalSince(dose.date) / 60
            return total + dose.units * insulinRemainingFraction(minutesSinceDose: minutes, actionHours: actionHours)
        }
    }

    // MARK: - Trend (rate of change)

    /// Readings further apart than this don't count as one continuous trace.
    static let trendMaxGap: TimeInterval = 15 * 60
    /// How far back from the latest reading the rate is measured.
    static let trendWindow: TimeInterval = 15 * 60
    /// The readings used must cover at least this much time, so two
    /// back-to-back fingersticks don't produce a wild rate.
    static let trendMinSpan: TimeInterval = 5 * 60

    /// Rate of change in mg/dL per minute at the latest sample, or `nil` if
    /// there isn't a recent, continuous run of readings to measure it from.
    static func rateOfChange(samples: [GlucoseSample]) -> Double? {
        let sorted = samples.sorted { $0.date < $1.date }
        guard let latest = sorted.last else { return nil }

        var run = [latest]
        for sample in sorted.dropLast().reversed() {
            guard let earliest = run.first,
                  earliest.date.timeIntervalSince(sample.date) <= trendMaxGap,
                  latest.date.timeIntervalSince(sample.date) <= trendWindow else { break }
            run.insert(sample, at: 0)
        }

        guard run.count >= 2,
              let first = run.first,
              latest.date.timeIntervalSince(first.date) >= trendMinSpan else { return nil }

        // Least-squares slope, x in minutes from the first point.
        let xs = run.map { $0.date.timeIntervalSince(first.date) / 60 }
        let ys = run.map(\.mgdl)
        let n = Double(run.count)
        let meanX = xs.reduce(0, +) / n
        let meanY = ys.reduce(0, +) / n
        var numerator = 0.0
        var denominator = 0.0
        for (x, y) in zip(xs, ys) {
            numerator += (x - meanX) * (y - meanY)
            denominator += (x - meanX) * (x - meanX)
        }
        guard denominator > 0 else { return nil }
        return numerator / denominator
    }

    /// CGM-style trend arrow from the rate of change, using the usual
    /// cut-offs: under 1 mg/dL/min is steady, 1–2 is rising or falling,
    /// 2 or more is rising or falling fast.
    static func trend(samples: [GlucoseSample]) -> GlucoseTrend? {
        guard let rate = rateOfChange(samples: samples) else { return nil }
        return trend(forRate: rate)
    }

    static func trend(forRate rate: Double) -> GlucoseTrend {
        switch rate {
        case 2...: return .risingFast
        case 1..<2: return .rising
        case ...(-2): return .fallingFast
        case -2...(-1): return .falling
        default: return .stable
        }
    }

    /// Overall direction across a longer stretch (a day, a weekday), from the
    /// least-squares slope in mg/dL per hour. Needs at least three readings
    /// spanning an hour; otherwise reports `.stable`.
    static func direction(samples: [GlucoseSample]) -> GlucoseTrend {
        let sorted = samples.sorted { $0.date < $1.date }
        guard sorted.count >= 3,
              let first = sorted.first, let last = sorted.last,
              last.date.timeIntervalSince(first.date) >= 3600 else { return .stable }

        let xs = sorted.map { $0.date.timeIntervalSince(first.date) / 3600 }
        let ys = sorted.map(\.mgdl)
        let n = Double(sorted.count)
        let meanX = xs.reduce(0, +) / n
        let meanY = ys.reduce(0, +) / n
        var numerator = 0.0
        var denominator = 0.0
        for (x, y) in zip(xs, ys) {
            numerator += (x - meanX) * (y - meanY)
            denominator += (x - meanX) * (x - meanX)
        }
        guard denominator > 0 else { return .stable }
        let perHour = numerator / denominator

        switch perHour {
        case 10...: return .risingFast
        case 5..<10: return .rising
        case ...(-10): return .fallingFast
        case -10...(-5): return .falling
        default: return .stable
        }
    }

    // MARK: - Statistics

    static func calculateStatistics(samples: [GlucoseSample], thresholds: GlucoseThresholds) -> GlucoseStatistics {
        guard !samples.isEmpty else { return GlucoseStatistics() }

        let average = calculateAverage(samples: samples)
        let standardDeviation = calculateStandardDeviation(samples: samples)
        let cv = average > 0 ? (standardDeviation / average) * 100 : 0

        return GlucoseStatistics(
            average: average,
            standardDeviation: standardDeviation,
            cv: cv,
            timeInRange: share(of: samples, where: { thresholds.zone(for: $0) == .inRange }),
            timeBelowRange: share(of: samples, where: { thresholds.zone(for: $0).isLow }),
            timeAboveRange: share(of: samples, where: { $0 > thresholds.targetHigh })
        )
    }

    /// Glucose management indicator: the A1C-like percentage estimated from
    /// mean glucose (Bergenstal et al., Diabetes Care 2018). Meant for at
    /// least 14 days of CGM data.
    static func glucoseManagementIndicator(averageMgdl: Double) -> Double {
        3.31 + 0.02392 * averageMgdl
    }

    /// Percentage of readings in the target range. This counts readings, so
    /// it only approximates time when readings are evenly spaced (CGM data).
    /// `hours` is that share of the span between the first and last reading.
    static func calculateTimeInRange(samples: [GlucoseSample], thresholds: GlucoseThresholds) -> (percentage: Double, hours: Double) {
        share(of: samples, where: { thresholds.zone(for: $0) == .inRange })
    }

    static func calculateAverage(samples: [GlucoseSample]) -> Double {
        guard !samples.isEmpty else { return 0 }
        return samples.reduce(0) { $0 + $1.mgdl } / Double(samples.count)
    }

    static func calculateStandardDeviation(samples: [GlucoseSample]) -> Double {
        guard !samples.isEmpty else { return 0 }
        let average = calculateAverage(samples: samples)
        let variance = samples.reduce(0) { $0 + pow($1.mgdl - average, 2) } / Double(samples.count)
        return sqrt(variance)
    }

    // MARK: - Helpers

    private static func share(of samples: [GlucoseSample], where matches: (Double) -> Bool) -> (percentage: Double, hours: Double) {
        guard !samples.isEmpty else { return (percentage: 0, hours: 0) }
        let count = samples.filter { matches($0.mgdl) }.count
        let percentage = Double(count) / Double(samples.count) * 100
        return (percentage: percentage, hours: timeSpanHours(samples) * percentage / 100)
    }

    /// Hours between the earliest and latest sample, regardless of order.
    private static func timeSpanHours(_ samples: [GlucoseSample]) -> Double {
        guard let earliest = samples.map(\.date).min(),
              let latest = samples.map(\.date).max() else { return 0 }
        return latest.timeIntervalSince(earliest) / 3600
    }
}
