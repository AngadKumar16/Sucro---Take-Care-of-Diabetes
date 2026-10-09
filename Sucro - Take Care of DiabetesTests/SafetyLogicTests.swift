//
//  SafetyLogicTests.swift
//  Sucro - Take Care of Diabetes Tests
//
//  Covers the glucose math and alert logic: thresholds, trend arrows,
//  insulin on board, alert de-duplication, reminders, and recovering from a
//  store that won't open.
//

import Testing
import Foundation
import CoreData
@testable import Sucro___Take_Care_of_Diabetes

// MARK: - Helpers

private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

private func minutes(_ m: Double) -> TimeInterval { m * 60 }

/// Readings every `every` minutes ending at `end`, starting from `start` and
/// changing by `slope` mg/dL per minute.
private func stream(count: Int, every: Double = 5, end: Date = t0, start: Double = 120, slope: Double) -> [GlucoseSample] {
    (0..<count).map { i in
        let offset = Double(count - 1 - i) * every
        return GlucoseSample(
            date: end.addingTimeInterval(-minutes(offset)),
            mgdl: start + slope * Double(i) * every
        )
    }
}

private func isolatedDefaults() -> (UserDefaults, () -> Void) {
    let name = "SucroTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    return (defaults, { defaults.removePersistentDomain(forName: name) })
}

private func tempStoreURL() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("SucroTest-\(UUID().uuidString).sqlite")
}

private func removeStore(at url: URL) {
    for suffix in ["", "-wal", "-shm"] {
        try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + suffix))
    }
}

// MARK: - Thresholds

struct GlucoseThresholdTests {
    let thresholds = GlucoseThresholds.standard  // 55 / 70 / 180 / 250

    @Test(arguments: [
        (54.0, GlucoseZone.urgentLow),
        (55.0, .low),
        (69.0, .low),
        (70.0, .inRange),
        (180.0, .inRange),
        (181.0, .high),
        (250.0, .high),
        (251.0, .urgentHigh),
    ])
    func zoneBoundaries(value: Double, expected: GlucoseZone) {
        #expect(thresholds.zone(for: value) == expected)
    }

    @Test func onlyLowsAndUrgentHighNeedAction() {
        #expect(GlucoseZone.urgentLow.needsAction)
        #expect(GlucoseZone.low.needsAction)
        #expect(GlucoseZone.urgentHigh.needsAction)
        #expect(!GlucoseZone.high.needsAction)
        #expect(!GlucoseZone.inRange.needsAction)
    }
}

struct GlucoseManagementIndicatorTests {
    // Reference points from Bergenstal et al. 2018, Table 1.
    @Test(arguments: [(100.0, 5.7), (154.0, 7.0), (200.0, 8.1)])
    func matchesPublishedTable(average: Double, expected: Double) {
        let gmi = GlucoseCalculator.glucoseManagementIndicator(averageMgdl: average)
        #expect(abs(gmi - expected) < 0.05)
    }
}

@MainActor
struct ThresholdSettingsTests {

    @Test func newThresholdsHaveDefaultsAndPersist() {
        let (defaults, cleanup) = isolatedDefaults()
        defer { cleanup() }

        let first = SettingsStore(defaults: defaults)
        #expect(first.thresholds == .standard)
        #expect(first.insulinActionHours == 4)

        first.urgentLow = 60
        first.urgentHigh = 300
        first.insulinActionHours = 5

        let second = SettingsStore(defaults: defaults)
        #expect(second.urgentLow == 60)
        #expect(second.urgentHigh == 300)
        #expect(second.insulinActionHours == 5)
    }

    @Test func legacyTargetBelowDefaultUrgentLowIsRepaired() {
        let (defaults, cleanup) = isolatedDefaults()
        defer { cleanup() }

        // An older build allowed a 50-60 target range and had no urgent lines.
        defaults.set(50.0, forKey: "settings.targetLow")
        defaults.set(60.0, forKey: "settings.targetHigh")

        let store = SettingsStore(defaults: defaults)
        let t = store.thresholds
        #expect(t.urgentLow < t.targetLow)
        #expect(t.targetLow < t.targetHigh)
        #expect(t.targetHigh < t.urgentHigh)
        // Stepper ranges must be valid (lower <= upper) or SwiftUI traps.
        for range in [store.urgentLowBounds, store.targetLowBounds, store.targetHighBounds, store.urgentHighBounds] {
            #expect(range.lowerBound <= range.upperBound)
        }
    }

    @Test func targetRangeCannotCrossUrgentLines() {
        let (defaults, cleanup) = isolatedDefaults()
        defer { cleanup() }

        let store = SettingsStore(defaults: defaults)
        store.targetRangeString = "50-150"   // below urgent low (55)
        #expect(store.targetLow == 70)
        store.targetRangeString = "80-260"   // above urgent high (250)
        #expect(store.targetHigh == 180)
    }

    @Test func colorsAndCriticalUseTheSameZones() {
        let (defaults, cleanup) = isolatedDefaults()
        defer { cleanup() }

        let store = SettingsStore(defaults: defaults)
        #expect(store.isCriticalGlucose(65))      // low
        #expect(!store.isCriticalGlucose(200))    // high but not urgent
        #expect(store.isCriticalGlucose(260))     // urgent high
        #expect(store.isInTargetRange(100))
    }
}

// MARK: - Insulin

struct InsulinTypeTests {
    @Test(arguments: [
        ("bolus", InsulinType.bolus), ("Rapid Acting", .bolus), ("rapid", .bolus),
        ("correction", .correction),
        ("basal", .basal), ("Long Acting", .basal), ("long", .basal),
        ("intermediate", .intermediate), ("Mixed", .mixed), ("Other", .other),
    ])
    func readsLegacyLabels(stored: String, expected: InsulinType) {
        #expect(InsulinType(stored: stored) == expected)
    }

    @Test func unknownLabelsAreNil() {
        #expect(InsulinType(stored: nil) == nil)
        #expect(InsulinType(stored: "") == nil)
        #expect(InsulinType(stored: "banana") == nil)
    }
}

struct InsulinOnBoardTests {
    @Test func curveStartsFullAndEndsEmpty() {
        #expect(GlucoseCalculator.insulinRemainingFraction(minutesSinceDose: 0, actionHours: 4) == 1)
        #expect(GlucoseCalculator.insulinRemainingFraction(minutesSinceDose: 240, actionHours: 4) == 0)
        #expect(GlucoseCalculator.insulinRemainingFraction(minutesSinceDose: 300, actionHours: 4) == 0)
    }

    @Test(arguments: [3.0, 4.0, 5.0, 6.0])
    func curveOnlyGoesDown(actionHours: Double) {
        var previous = 1.0
        for minute in stride(from: 5.0, through: actionHours * 60, by: 5) {
            let fraction = GlucoseCalculator.insulinRemainingFraction(minutesSinceDose: minute, actionHours: actionHours)
            #expect(fraction <= previous)
            #expect((0...1).contains(fraction))
            previous = fraction
        }
    }

    @Test func curveHasTheExpectedShape() {
        // Insulin takes a while to start working, so more remains early on
        // than a straight line would say, and less in the tail.
        let early = GlucoseCalculator.insulinRemainingFraction(minutesSinceDose: 30, actionHours: 4)
        let late = GlucoseCalculator.insulinRemainingFraction(minutesSinceDose: 180, actionHours: 4)
        #expect(early > 1 - 30.0 / 240)
        #expect(late < 1 - 180.0 / 240)

        // Pin a few values of the Loop/OpenAPS exponential curve (75 min peak).
        let reference: [(minutes: Double, hours: Double, remaining: Double)] = [
            (60, 4, 0.737), (120, 4, 0.342), (60, 6, 0.779), (180, 6, 0.208),
        ]
        for point in reference {
            let value = GlucoseCalculator.insulinRemainingFraction(minutesSinceDose: point.minutes, actionHours: point.hours)
            #expect(abs(value - point.remaining) < 0.001)
        }
    }

    @Test func countsOnlyRapidActingPastDoses() {
        let now = t0
        let doses = [
            InsulinDose(date: now, units: 4, type: .bolus),                                   // all active
            InsulinDose(date: now.addingTimeInterval(-minutes(30)), units: 2, type: .correction),
            InsulinDose(date: now.addingTimeInterval(-minutes(10)), units: 20, type: .basal),  // ignored
            InsulinDose(date: now.addingTimeInterval(-minutes(10)), units: 8, type: .mixed),   // ignored
            InsulinDose(date: now.addingTimeInterval(-minutes(10)), units: 8, type: nil),      // ignored
            InsulinDose(date: now.addingTimeInterval(minutes(30)), units: 5, type: .bolus),    // future, ignored
            InsulinDose(date: now.addingTimeInterval(-minutes(300)), units: 5, type: .bolus),  // expired
        ]
        let iob = GlucoseCalculator.insulinOnBoard(doses: doses, at: now, actionHours: 4)
        let correctionLeft = 2 * GlucoseCalculator.insulinRemainingFraction(minutesSinceDose: 30, actionHours: 4)
        #expect(abs(iob - (4 + correctionLeft)) < 0.0001)
    }

    @MainActor
    @Test func dataServiceUsesTheSameCurve() {
        let url = tempStoreURL()
        defer { removeStore(at: url) }
        let persistence = PersistenceController(storeURL: url)
        let context = persistence.container.viewContext

        let now = Date()
        let entry = InsulinEntry(context: context)
        entry.id = UUID()
        entry.timestamp = now.addingTimeInterval(-minutes(60))
        entry.units = 5
        entry.type = "Rapid Acting"   // label older builds saved from the Log tab
        try? context.save()

        let expected = 5 * GlucoseCalculator.insulinRemainingFraction(
            minutesSinceDose: 60, actionHours: SettingsStore.shared.insulinActionHours
        )
        let iob = DataService.shared.calculateIOB(context: context, at: now)
        #expect(abs(iob - expected) < 0.0001)
    }
}

// MARK: - Trend

struct TrendTests {
    @Test(arguments: [
        (2.5, GlucoseTrend.risingFast),
        (1.5, .rising),
        (0.0, .stable),
        (-0.5, .stable),
        (-1.5, .falling),
        (-3.0, .fallingFast),
    ])
    func arrowFromRate(slope: Double, expected: GlucoseTrend) {
        let samples = stream(count: 4, slope: slope)
        #expect(GlucoseCalculator.trend(samples: samples) == expected)
    }

    @Test func orderOfInputDoesNotMatter() {
        let samples = stream(count: 4, slope: 2.5)
        #expect(GlucoseCalculator.trend(samples: samples.reversed()) == .risingFast)
        #expect(GlucoseCalculator.trend(samples: samples.shuffled()) == .risingFast)
    }

    @Test func rateIsMeasuredInMgdlPerMinute() throws {
        let rate = try #require(GlucoseCalculator.rateOfChange(samples: stream(count: 3, slope: 1.2)))
        #expect(abs(rate - 1.2) < 0.0001)
    }

    @Test func noTrendWithoutRecentContinuousReadings() {
        // One reading.
        #expect(GlucoseCalculator.trend(samples: [GlucoseSample(date: t0, mgdl: 100)]) == nil)
        // Two readings 20 minutes apart: a gap, not a trace.
        #expect(GlucoseCalculator.trend(samples: [
            GlucoseSample(date: t0.addingTimeInterval(-minutes(20)), mgdl: 100),
            GlucoseSample(date: t0, mgdl: 150),
        ]) == nil)
        // Two fingersticks two minutes apart: too short to measure.
        #expect(GlucoseCalculator.trend(samples: [
            GlucoseSample(date: t0.addingTimeInterval(-minutes(2)), mgdl: 100),
            GlucoseSample(date: t0, mgdl: 110),
        ]) == nil)
    }

    @Test func oldReadingsBeyondTheWindowAreIgnored() {
        // Steady for the last 15 minutes after a big earlier climb.
        var samples = stream(count: 4, end: t0, start: 200, slope: 0)
        samples.append(GlucoseSample(date: t0.addingTimeInterval(-minutes(20)), mgdl: 100))
        #expect(GlucoseCalculator.trend(samples: samples) == .stable)
    }

    @Test func directionOfUnsortedDayIsCorrect() {
        let hours = (0..<6).map { h in
            GlucoseSample(date: t0.addingTimeInterval(Double(h) * 3600), mgdl: 100 + Double(h) * 12)
        }
        #expect(GlucoseCalculator.direction(samples: hours.shuffled()) == .risingFast)
        #expect(GlucoseCalculator.direction(samples: Array(hours.prefix(2))) == .stable)
    }

    @Test(arguments: [
        ("rising_fast", GlucoseTrend.risingFast), ("doubleUp", .risingFast),
        ("up", .rising), ("flat", .stable), ("down", .falling), ("falling_fast", .fallingFast),
    ])
    func readsStoredTrends(stored: String, expected: GlucoseTrend) {
        #expect(GlucoseTrend(stored: stored) == expected)
    }
}

// MARK: - Statistics

struct StatisticsTests {
    @Test func timeInRangeUsesTheGivenThresholdsAndAnyOrder() {
        let samples = [
            GlucoseSample(date: t0.addingTimeInterval(3600), mgdl: 100),
            GlucoseSample(date: t0, mgdl: 60),
            GlucoseSample(date: t0.addingTimeInterval(1800), mgdl: 200),
            GlucoseSample(date: t0.addingTimeInterval(5400), mgdl: 150),
        ]
        let stats = GlucoseCalculator.calculateStatistics(samples: samples, thresholds: .standard)
        #expect(stats.timeInRange.percentage == 50)
        #expect(stats.timeBelowRange.percentage == 25)
        #expect(stats.timeAboveRange.percentage == 25)
        // Span is 1.5 h even though input isn't sorted.
        #expect(abs(stats.timeInRange.hours - 0.75) < 0.0001)

        let tight = GlucoseThresholds(urgentLow: 55, targetLow: 70, targetHigh: 140, urgentHigh: 250)
        #expect(GlucoseCalculator.calculateTimeInRange(samples: samples, thresholds: tight).percentage == 25)
    }
}

// MARK: - Alert policy

struct GlucoseAlertPolicyTests {
    let policy = GlucoseAlertPolicy()
    let thresholds = GlucoseThresholds.standard

    private func evaluate(_ mgdl: Double, at time: Date, readAt: Date? = nil, state: AlertState) -> GlucoseAlertPolicy.GlucoseDecision {
        policy.evaluateGlucose(
            latest: GlucoseSample(date: readAt ?? time, mgdl: mgdl),
            thresholds: thresholds,
            state: state,
            now: time
        )
    }

    @Test func notifiesOncePerLowEpisode() {
        var state = AlertState()

        let first = evaluate(65, at: t0, state: state)
        #expect(first.notify == .low)
        state = first.state

        // Same reading seen again on every Home refresh: no repeat.
        for _ in 0..<5 {
            let again = evaluate(65, at: t0.addingTimeInterval(10), readAt: t0, state: state)
            #expect(again.notify == nil)
            state = again.state
        }

        // Still low on the next reading: same episode, no repeat.
        let next = evaluate(62, at: t0.addingTimeInterval(minutes(5)), state: state)
        #expect(next.notify == nil)
    }

    @Test func bouncingAcrossTheLineRespectsCooldown() {
        var state = evaluate(65, at: t0, state: AlertState()).state
        state = evaluate(75, at: t0.addingTimeInterval(minutes(5)), state: state).state
        #expect(state.activeEpisode == nil)

        let soon = evaluate(66, at: t0.addingTimeInterval(minutes(10)), state: state)
        #expect(soon.notify == nil)
        #expect(soon.state.activeEpisode == .low)

        // Back in range, then low again after the cooldown: notify.
        state = evaluate(80, at: t0.addingTimeInterval(minutes(15)), state: soon.state).state
        let later = evaluate(64, at: t0.addingTimeInterval(minutes(45)), state: state)
        #expect(later.notify == .low)
    }

    @Test func escalatingToUrgentLowAlwaysNotifies() {
        let low = evaluate(65, at: t0, state: AlertState())
        let urgent = evaluate(50, at: t0.addingTimeInterval(minutes(5)), state: low.state)
        #expect(urgent.notify == .urgentLow)

        // Easing back to plain low is not news.
        let eased = evaluate(60, at: t0.addingTimeInterval(minutes(10)), state: urgent.state)
        #expect(eased.notify == nil)
        #expect(eased.state.activeEpisode == .low)
    }

    @Test func mildHighIsQuietUrgentHighNotifies() {
        let mild = evaluate(200, at: t0, state: AlertState())
        #expect(mild.notify == nil)
        let urgent = evaluate(280, at: t0.addingTimeInterval(minutes(5)), state: mild.state)
        #expect(urgent.notify == .urgentHigh)
    }

    @Test func oldReadingsNeverNotify() {
        let decision = evaluate(50, at: t0, readAt: t0.addingTimeInterval(-minutes(40)), state: AlertState())
        #expect(decision.notify == nil)
        #expect(decision.state == AlertState())
    }

    @Test func stateSurvivesEncoding() throws {
        let state = evaluate(65, at: t0, state: AlertState()).state
        let decoded = try JSONDecoder().decode(AlertState.self, from: JSONEncoder().encode(state))
        #expect(decoded == state)
    }

    @Test func fingersticksAreNotACGMStream() {
        let manual = [
            GlucoseSample(date: t0.addingTimeInterval(-minutes(240)), mgdl: 120),
            GlucoseSample(date: t0.addingTimeInterval(-minutes(120)), mgdl: 140),
            GlucoseSample(date: t0, mgdl: 110),
        ]
        #expect(!policy.isContinuousStream(manual))
        #expect(policy.staleDeadline(for: manual) == nil)
    }

    @Test func cgmStreamGoesStaleTwentyMinutesAfterLastReading() {
        let cgm = stream(count: 6, slope: 0)
        #expect(policy.isContinuousStream(cgm))
        #expect(policy.staleDeadline(for: cgm) == t0.addingTimeInterval(minutes(20)))
    }
}

// MARK: - Alert service (Core Data + persistence)

@MainActor
struct AlertServiceTests {

    @Test func repeatedEvaluationKeepsOneEpisodeAndShowsBanner() {
        let url = tempStoreURL()
        defer { removeStore(at: url) }
        let (defaults, cleanup) = isolatedDefaults()
        defer { cleanup() }

        let persistence = PersistenceController(storeURL: url)
        let context = persistence.container.viewContext
        let settings = SettingsStore(defaults: defaults)
        settings.notificationsEnabled = false

        let now = Date()
        let reading = GlucoseReading(context: context)
        reading.id = UUID()
        reading.timestamp = now.addingTimeInterval(-60)
        reading.value = 62
        try? context.save()

        let service = AlertService(defaults: defaults)
        let banner = service.evaluate(context: context, settings: settings, now: now)
        #expect(banner == .lowGlucose(62))
        let firstNotified = service.state.lastNotified[.low]
        #expect(firstNotified == now)

        // Evaluating again (as every Home refresh does) changes nothing.
        service.evaluate(context: context, settings: settings, now: now.addingTimeInterval(30))
        #expect(service.state.lastNotified[.low] == firstNotified)
        #expect(service.state.activeEpisode == .low)

        // A fresh service reading the same defaults remembers the episode.
        let relaunched = AlertService(defaults: defaults)
        #expect(relaunched.state.activeEpisode == .low)
    }

    @Test func sparseManualReadingsNeverShowStaleBanner() {
        let url = tempStoreURL()
        defer { removeStore(at: url) }
        let (defaults, cleanup) = isolatedDefaults()
        defer { cleanup() }

        let persistence = PersistenceController(storeURL: url)
        let context = persistence.container.viewContext
        let settings = SettingsStore(defaults: defaults)
        settings.notificationsEnabled = false

        let reading = GlucoseReading(context: context)
        reading.id = UUID()
        reading.timestamp = Date().addingTimeInterval(-6 * 3600)
        reading.value = 120
        try? context.save()

        let banner = AlertService(defaults: defaults).evaluate(context: context, settings: settings)
        #expect(banner == nil)
    }

    @Test func cgmGapShowsStaleBanner() {
        let url = tempStoreURL()
        defer { removeStore(at: url) }
        let (defaults, cleanup) = isolatedDefaults()
        defer { cleanup() }

        let persistence = PersistenceController(storeURL: url)
        let context = persistence.container.viewContext
        let settings = SettingsStore(defaults: defaults)
        settings.notificationsEnabled = false

        let now = Date()
        let lastReading = now.addingTimeInterval(-minutes(45))
        for sample in stream(count: 6, end: lastReading, slope: 0) {
            let reading = GlucoseReading(context: context)
            reading.id = UUID()
            reading.timestamp = sample.date
            reading.value = sample.mgdl
        }
        try? context.save()

        let banner = AlertService(defaults: defaults).evaluate(context: context, settings: settings, now: now)
        #expect(banner == .cgmDataStale(minutes: 45))
    }
}

// MARK: - Reminders

@MainActor
struct ReminderPlannerTests {
    @Test func idsAreStablePerOccurrence() {
        let change = ReminderPlanner.SiteChangeInfo(date: t0, rotationDays: 3)
        let first = ReminderPlanner.plan(lastSiteChange: change, lastRapidDose: t0)
        let second = ReminderPlanner.plan(lastSiteChange: change, lastRapidDose: t0)
        #expect(first == second)
        #expect(Set(first.map(\.id)).count == 2)
        #expect(first.allSatisfy { $0.id.hasPrefix(NotificationService.Identifier.reminderPrefix) })
    }

    @Test func timesComeFromTheEventsNotFromNow() {
        let change = ReminderPlanner.SiteChangeInfo(date: t0, rotationDays: 2)
        let plan = ReminderPlanner.plan(lastSiteChange: change, lastRapidDose: t0)
        let site = plan.first { $0.kind == .siteChange }
        let check = plan.first { $0.kind == .glucoseCheck }
        #expect(site?.time == Calendar.current.date(byAdding: .day, value: 2, to: t0))
        #expect(check?.time == t0.addingTimeInterval(2 * 3600))
    }
}

@MainActor
struct ReminderServiceTests {

    private func makeStore() -> (NSManagedObjectContext, URL) {
        let url = tempStoreURL()
        let persistence = PersistenceController(storeURL: url)
        return (persistence.container.viewContext, url)
    }

    @Test func completedAndSnoozedRemindersStickAcrossRefreshes() throws {
        let (context, url) = makeStore()
        defer { removeStore(at: url) }
        let (defaults, cleanup) = isolatedDefaults()
        defer { cleanup() }

        let now = Date()
        let change = SiteChange(context: context)
        change.id = UUID()
        change.timestamp = now.addingTimeInterval(-3600)
        change.location = SiteLocation.thighLeft.rawValue  // 3-day rotation

        let dose = InsulinEntry(context: context)
        dose.id = UUID()
        dose.timestamp = now.addingTimeInterval(-1800)
        dose.units = 3
        dose.type = InsulinType.bolus.rawValue
        try context.save()

        let service = ReminderService(defaults: defaults)
        service.refresh(context: context, now: now)
        #expect(service.upcomingReminders.count == 2)

        // Refreshing again doesn't duplicate.
        service.refresh(context: context, now: now)
        #expect(service.upcomingReminders.count == 2)

        let check = try #require(service.upcomingReminders.first { $0.type == .glucoseCheck })
        service.complete(check)
        service.refresh(context: context, now: now)
        #expect(!service.upcomingReminders.contains { $0.id == check.id })

        let site = try #require(service.upcomingReminders.first { $0.type == .siteChange })
        service.snooze(site, minutes: 60, now: now)
        service.refresh(context: context, now: now)
        let snoozed = try #require(service.upcomingReminders.first { $0.id == site.id })
        #expect(snoozed.time == site.time.addingTimeInterval(3600))
    }
}

// MARK: - Persistence recovery

@MainActor
struct PersistenceRecoveryTests {

    @Test func damagedStoreReportsErrorInsteadOfCrashing() throws {
        let url = tempStoreURL()
        defer { removeStore(at: url) }
        try Data("this is not a database".utf8).write(to: url)

        let persistence = PersistenceController(storeURL: url)
        #expect(persistence.loadError != nil)

        persistence.resetStore()
        #expect(persistence.loadError == nil)

        // The fresh store works.
        let context = persistence.container.viewContext
        let reading = GlucoseReading(context: context)
        reading.id = UUID()
        reading.timestamp = Date()
        reading.value = 100
        try context.save()
        #expect(DataService.shared.fetchRecentGlucoseReadings(context: context).count == 1)
    }
}

// MARK: - Glucose shown on timeline events

@MainActor
struct EventGlucoseTests {

    @Test func onlyARecentReadingCountsAsGlucoseAtAnEvent() {
        let url = tempStoreURL()
        defer { removeStore(at: url) }
        let context = PersistenceController(storeURL: url).container.viewContext
        let meal = Date()

        // Nothing logged: nothing to show, not a made-up value.
        #expect(DataService.shared.getGlucoseAtTime(context: context, time: meal) == nil)

        func log(_ value: Double, minutesFromMeal: Double) {
            let reading = GlucoseReading(context: context)
            reading.id = UUID()
            reading.timestamp = meal.addingTimeInterval(minutes(minutesFromMeal))
            reading.value = value
        }

        log(200, minutesFromMeal: -120)   // too old
        log(90, minutesFromMeal: 10)      // after the meal
        try? context.save()
        #expect(DataService.shared.getGlucoseAtTime(context: context, time: meal) == nil)

        log(140, minutesFromMeal: -10)
        try? context.save()
        #expect(DataService.shared.getGlucoseAtTime(context: context, time: meal) == 140)
    }
}
