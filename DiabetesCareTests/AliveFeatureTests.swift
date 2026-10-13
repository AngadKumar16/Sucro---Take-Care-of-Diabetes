//
//  AliveFeatureTests.swift
//  DiabetesCare Tests
//
//  The "more alive" features: day and night stories, streaks, the plant,
//  the typical-day profile, meal impact, day tags, ketone levels, food
//  lookup, supplies, routes, Health context findings, backups of the new
//  entries, and help replies over family sharing.
//

import Testing
import Foundation
import CoreData
@testable import DiabetesCare

private let t0 = Date(timeIntervalSince1970: 1_800_000_000)
private let calendar = Calendar.current
private let thresholds = GlucoseThresholds.standard

private func tempURL(_ suffix: String) -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("DiabetesCareAliveTest-\(UUID().uuidString)\(suffix)")
}

private func removeStore(at url: URL) {
    for suffix in ["", "-wal", "-shm"] {
        try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + suffix))
    }
}

private func isolatedDefaults() -> (UserDefaults, () -> Void) {
    let name = "DiabetesCareAliveTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    return (defaults, { defaults.removePersistentDomain(forName: name) })
}

/// Readings every `minutes` from `start` with the given values.
private func series(from start: Date, every minutes: Double = 5, _ values: [Double]) -> [GlucoseSample] {
    values.enumerated().map { GlucoseSample(date: start.addingTimeInterval(Double($0.offset) * minutes * 60), mgdl: $0.element) }
}

@Suite("Stories")
struct StoryTests {
    @Test func stretchesBreakOnOutOfRangeAndGaps() {
        let start = calendar.startOfDay(for: t0)
        var samples = series(from: start, [100, 110, 120, 200, 130, 140])
        // A 40-minute gap splits the second run.
        samples.append(GlucoseSample(date: samples.last!.date.addingTimeInterval(40 * 60), mgdl: 120))
        let runs = Story.stretches(samples) { thresholds.zone(for: $0) == .inRange }
        #expect(runs.count == 3)
        #expect(runs[0].duration == 10 * 60)
        #expect(runs[1].duration == 5 * 60)
    }

    @Test func lowsCountOncePerEpisodeAndTreatmentIsNoticed() {
        let start = calendar.startOfDay(for: t0).addingTimeInterval(8 * 3600)
        let samples = series(from: start, [120, 65, 60, 72, 110, 64, 100])
        let episodes = Story.lowEpisodes(samples, thresholds: thresholds)
        #expect(episodes.count == 2)

        let day = Story.day(
            samples: samples,
            carbTimes: [episodes[0].addingTimeInterval(5 * 60)],
            thresholds: thresholds,
            in: DateInterval(start: calendar.startOfDay(for: t0), duration: 86_400)
        )
        #expect(day?.lows == 2)
        #expect(day?.lowsTreated == 1)
        #expect(day?.lowest == 60)
        #expect(day?.highest == 120)
    }

    @Test func sentenceMentionsLowsAndRange() throws {
        let start = calendar.startOfDay(for: t0).addingTimeInterval(8 * 3600)
        let samples = series(from: start, Array(repeating: 120, count: 30))
        let day = try #require(Story.day(samples: samples, carbTimes: [], thresholds: thresholds,
                                         in: DateInterval(start: calendar.startOfDay(for: t0), duration: 86_400)))
        let text = Story.sentence(for: day) { "\(Int($0))" }
        #expect(text.contains("No lows"))
        #expect(text.contains("120–120"))
        #expect(day.inRangePercent == 100)
    }

    @Test func nightNeedsAFewReadingsAndKnowsSteady() throws {
        let midnight = calendar.startOfDay(for: t0)
        #expect(Story.night(samples: series(from: midnight, [100, 110]), thresholds: thresholds, now: t0) == nil)
        let night = try #require(Story.night(samples: series(from: midnight, every: 60, [100, 110, 120, 105]), thresholds: thresholds,
                                             now: midnight.addingTimeInterval(8 * 3600)))
        #expect(night.isSteady)
        #expect(night.lows == 0)
        #expect(Story.sentence(for: night) { "\(Int($0))" }.contains("Steady night"))
    }

    @Test func weekComparesWithTheWeekBefore() throws {
        let now = calendar.startOfDay(for: t0).addingTimeInterval(20 * 3600)
        var samples: [GlucoseSample] = []
        for day in 0..<14 {
            let start = calendar.startOfDay(for: now).addingTimeInterval(-Double(day) * 86_400 + 8 * 3600)
            // This week all in range; the week before half high.
            let values: [Double] = day < 7 ? [120, 130, 140, 150] : [120, 200, 130, 210]
            samples += series(from: start, every: 60, values)
        }
        let week = try #require(Story.week(samples: samples, loggedDates: [now, now.addingTimeInterval(-86_400)], thresholds: thresholds, now: now))
        #expect(week.inRangePercent == 100)
        #expect(week.previousInRangePercent == 50)
        #expect(week.loggedDays == 2)
        #expect(week.steadiestDay != nil)
    }
}

@Suite("Streaks and growth")
struct StreakTests {
    @Test func daysWithoutUrgentLowCountFromTheDayAfter() {
        let now = calendar.startOfDay(for: t0).addingTimeInterval(12 * 3600)
        let first = GlucoseSample(date: now.addingTimeInterval(-10 * 86_400), mgdl: 120)
        let urgent = GlucoseSample(date: now.addingTimeInterval(-3 * 86_400), mgdl: 50)
        #expect(Streaks.daysWithoutUrgentLow(samples: [first, urgent], thresholds: thresholds, now: now) == 3)
        #expect(Streaks.daysWithoutUrgentLow(samples: [first], thresholds: thresholds, now: now) == 11)
        #expect(Streaks.daysWithoutUrgentLow(samples: [], thresholds: thresholds, now: now) == 0)
    }

    @Test func sitesOnTimeStopsAtTheFirstOverdueChange() {
        let now = t0
        let changes = [
            SiteRotation.Change(location: .abdomenLeft, date: now.addingTimeInterval(-1 * 86_400)),   // in use
            SiteRotation.Change(location: .armLeft, date: now.addingTimeInterval(-4 * 86_400)),       // worn 3 of 4 days
            SiteRotation.Change(location: .thighLeft, date: now.addingTimeInterval(-7 * 86_400)),     // worn 3 days
            SiteRotation.Change(location: .thighRight, date: now.addingTimeInterval(-14 * 86_400)),   // worn 7: overdue
        ]
        #expect(Streaks.sitesOnTime(changes, now: now) == 2)
    }

    @Test func milestonesAreCelebratedOnce() {
        #expect(Streaks.newMilestone(value: 7, lastCelebrated: 3) == 7)
        #expect(Streaks.newMilestone(value: 7, lastCelebrated: 7) == nil)
        #expect(Streaks.newMilestone(value: 8, lastCelebrated: 7) == nil)
    }

    @Test func plantGrowsWithSkillsAndStreaks() {
        #expect(SproutGrowth.level(skills: 0, streak: 0) == .seed)
        #expect(SproutGrowth.level(skills: 1, streak: 0) == .sprout)
        #expect(SproutGrowth.level(skills: 2, streak: 7) == .seedling)
        #expect(SproutGrowth.level(skills: 6, streak: 14) == .flower)
    }
}

@Suite("Trends")
struct TrendsLogicTests {
    @Test func percentileInterpolates() {
        #expect(AGP.percentile([10, 20, 30, 40, 50], 0.5) == 30)
        #expect(AGP.percentile([10, 20], 0.5) == 15)
        #expect(AGP.percentile([], 0.5) == 0)
    }

    @Test func profileNeedsEnoughDaysAndOrdersBands() throws {
        let base = calendar.startOfDay(for: t0)
        var samples: [GlucoseSample] = []
        for day in 0..<6 {
            for (index, value) in [100.0, 120, 140, 160, 180].enumerated() {
                samples.append(GlucoseSample(date: base.addingTimeInterval(Double(day) * 86_400 + 8 * 3600 + Double(index) * 60), mgdl: value + Double(day)))
            }
        }
        #expect(AGP.profile(samples: Array(samples.prefix(20))).isEmpty, "4 days isn't enough")
        let profile = AGP.profile(samples: samples)
        let bucket = try #require(profile.first)
        #expect(bucket.minute == 8 * 60 + 15)
        #expect(bucket.p5 <= bucket.p25 && bucket.p25 <= bucket.median && bucket.median <= bucket.p75 && bucket.p75 <= bucket.p95)
    }

    @Test func mealImpactMeasuresTheRiseAndSkipsStackedMeals() throws {
        let meal = t0
        let samples = [
            GlucoseSample(date: meal.addingTimeInterval(-10 * 60), mgdl: 110),
            GlucoseSample(date: meal.addingTimeInterval(60 * 60), mgdl: 190),
            GlucoseSample(date: meal.addingTimeInterval(120 * 60), mgdl: 150),
        ]
        let meals = MealImpact.meals(entries: [MealImpact.Entry(time: meal, name: "Pizza", carbs: 60)], samples: samples)
        let first = try #require(meals.first)
        #expect(first.rise == 80)
        #expect(first.twoHours == 150)

        let stacked = MealImpact.meals(entries: [
            MealImpact.Entry(time: meal, name: "Pizza", carbs: 60),
            MealImpact.Entry(time: meal.addingTimeInterval(30 * 60), name: "Cake", carbs: 30),
        ], samples: samples)
        #expect(!stacked.contains { $0.name == "Pizza" }, "a meal followed by another within 90 minutes is skipped")
    }

    @Test func foodsGroupByNameCaseInsensitively() {
        let meals = [
            MealImpact.Meal(time: t0, name: "Pasta", carbs: 60, before: 100, peak: 200, twoHours: nil),
            MealImpact.Meal(time: t0.addingTimeInterval(86_400), name: "pasta", carbs: 50, before: 100, peak: 160, twoHours: nil),
            MealImpact.Meal(time: t0.addingTimeInterval(2 * 86_400), name: "Eggs", carbs: 10, before: 100, peak: 110, twoHours: nil),
        ]
        let foods = MealImpact.foods(meals)
        #expect(foods.count == 1)
        #expect(foods.first?.averageRise == 80)
    }

    @Test func tagInsightsCompareTaggedDaysWithTheRest() {
        let base = calendar.startOfDay(for: t0)
        var samples: [GlucoseSample] = []
        for day in 0..<6 {
            let value: Double = day < 2 ? 220 : 120
            samples += series(from: base.addingTimeInterval(Double(day) * 86_400 + 9 * 3600), every: 60, [value, value])
        }
        let tags: [(DayTag, Date)] = [(.sick, base.addingTimeInterval(10 * 3600)), (.sick, base.addingTimeInterval(86_400 + 10 * 3600))]
        let results = TagInsights.compare(samples: samples, tags: tags, thresholds: thresholds)
        #expect(results.count == 1)
        #expect(results.first?.tag == .sick)
        #expect(results.first?.average == 220)
        #expect(results.first?.otherAverage == 120)
        #expect(TagInsights.compare(samples: samples, tags: Array(tags.prefix(1)), thresholds: thresholds).isEmpty)
    }

    @Test func healthContextFindsLowerNightsAfterWorkouts() {
        let base = calendar.startOfDay(for: t0)
        var days: [DayContext] = []
        var samples: [GlucoseSample] = []
        for day in 0..<4 {
            let date = base.addingTimeInterval(Double(day) * 86_400)
            days.append(DayContext(day: date, steps: 8000, workoutMinutes: day.isMultiple(of: 2) ? 45 : 0, sleepHours: 8))
            let night = date.addingTimeInterval(86_400)
            samples += series(from: night, every: 60, Array(repeating: day.isMultiple(of: 2) ? 100 : 150, count: 4))
        }
        let findings = HealthContextInsights.findings(days: days, samples: samples) { "\(Int($0))" }
        #expect(findings.contains { $0.title.contains("Lower nights") })
        #expect(findings.contains { $0.title == "Sleep" })
    }
}

@Suite("Logging extras")
struct LoggingExtrasTests {
    @Test func ketoneZonesFollowCommonThresholds() {
        #expect(KetoneZone(value: 0.4, method: .blood) == .normal)
        #expect(KetoneZone(value: 1.0, method: .blood) == .raised)
        #expect(KetoneZone(value: 2.0, method: .blood) == .high)
        #expect(KetoneZone(value: 3.5, method: .blood) == .veryHigh)
        #expect(KetoneZone(value: Double(UrineKetones.moderate.rawValue), method: .urine) == .high)
        #expect(KetoneZone.display(value: Double(UrineKetones.small.rawValue), method: .urine) == "Small")
    }

    @Test func foodSearchRanksPlainMatchesFirst() {
        func food(_ name: String, _ source: FoodItem.Source = .usda) -> FoodItem {
            FoodItem(id: name, name: name, carbsPer100g: 10, fiberPer100g: 0, portions: [], source: source)
        }
        let foods = [food("Pie, apple"), food("Apple juice, 100%"), food("Apple, raw"), food("Pineapple"), food("Bread, white")]
        let results = FoodSearch.search("apple", in: foods)
        #expect(results.first?.name == "Apple, raw")
        #expect(!results.contains { $0.name == "Bread, white" })
        #expect(FoodSearch.search("apple raw", in: foods).map(\.name) == ["Apple, raw"])
        #expect(FoodSearch.search("   ", in: foods).isEmpty)
    }

    @Test func portionMathAndDefaultPortion() {
        let apple = FoodItem(id: "a", name: "Apple, raw", carbsPer100g: 14.8, fiberPer100g: 2.1,
                             portions: [FoodPortion(name: "1 small", grams: 165), FoodPortion(name: "1 medium", grams: 200)], source: .usda)
        #expect(apple.defaultPortion?.name == "1 medium")
        #expect(apple.carbs(portion: FoodPortion(name: "1 medium", grams: 200), amount: 1) == 30)
        #expect(apple.carbs(portion: FoodPortion(name: "1 medium", grams: 200), amount: 0.5) == 15)
    }

    @Test func bundledFoodDatabaseLoads() async {
        let foods = await FoodDatabase.shared.all()
        #expect(foods.count > 5000)
        let apple = FoodSearch.search("apple raw", in: foods).first
        #expect(apple?.name == "Apple, raw")
        #expect(apple?.portions.contains { $0.name == "1 medium" } == true)
    }

    @Test func openFoodFactsParsesPer100gAndPerServing() throws {
        let per100 = Data("""
        {"status":1,"product":{"product_name":"Choco Bar","brands":"Acme, Big Co","serving_size":"40 g","serving_quantity":"40","nutriments":{"carbohydrates_100g":60,"fiber_100g":"3"}}}
        """.utf8)
        let bar = try OpenFoodFacts.parse(per100, barcode: "0123456789012")
        #expect(bar.carbsPer100g == 60)
        #expect(bar.brand == "Acme")
        #expect(bar.carbs(portion: bar.portions[0], amount: 1) == 24)
        #expect(bar.source == .label)

        let servingOnly = Data("""
        {"status":1,"product":{"product_name":"Juice","serving_quantity":200,"nutriments":{"carbohydrates_serving":22}}}
        """.utf8)
        #expect(try OpenFoodFacts.parse(servingOnly, barcode: "123456").carbsPer100g == 11)

        #expect(throws: OpenFoodFacts.LookupError.self) {
            try OpenFoodFacts.parse(Data(#"{"status":0}"#.utf8), barcode: "123456")
        }
        #expect(OpenFoodFacts.url(for: "12") == nil)
        #expect(OpenFoodFacts.url(for: "0123456789012")?.absoluteString.contains("/product/0123456789012.json") == true)
    }

    @MainActor
    @Test func customFoodKeepsCarbsPerServing() {
        let soup = FoodLibrary.custom(name: "Grandma's soup", carbs: 20, servingName: "1 bowl", servingGrams: 250)
        #expect(soup.carbs(portion: soup.portions[0], amount: 1) == 20)
        let noWeight = FoodLibrary.custom(name: "Snack", carbs: 12, servingName: "", servingGrams: nil)
        #expect(noWeight.carbs(portion: noWeight.portions[0], amount: 2) == 24)
    }

    @MainActor
    @Test func suppliesTrackUseAndSiteChanges() {
        let (defaults, cleanup) = isolatedDefaults()
        defer { cleanup() }
        let kit = KitStore(defaults: defaults)
        kit.setCount(5, for: .infusionSet)
        kit.setCount(4, for: .reservoir)
        kit.setCount(10, for: .testStrip)
        kit.recordSiteChange()
        #expect(kit.supply(.infusionSet)?.count == 4)
        #expect(kit.supply(.reservoir)?.count == 3)
        #expect(kit.supply(.testStrip)?.count == 10)
        #expect(kit.lowSupplies.map(\.kind).contains(.reservoir))
        kit.use(.reservoir, count: 10)
        #expect(kit.supply(.reservoir)?.count == 0, "never below zero")

        kit.addQuestion("  Should I change my ranges?  ")
        kit.addQuestion("   ")
        #expect(kit.questions.map(\.text) == ["Should I change my ranges?"])

        // Survives a relaunch.
        let reloaded = KitStore(defaults: defaults)
        #expect(reloaded.archive == kit.archive)
    }

    @Test func openedInsulinCountsDaysLeft() {
        let opened = OpenedInsulin(name: "Pen", openedAt: calendar.startOfDay(for: t0), lastsDays: 28)
        #expect(opened.daysLeft(now: calendar.startOfDay(for: t0).addingTimeInterval(20 * 86_400 + 3600)) == 8)
    }
}

@Suite("Routes")
struct RouteTests {
    @Test func everyRouteSurvivesItsURL() {
        let routes: [AppRouter.Route] = [.logGlucose, .logCarbs, .getHelp, .trends, .weeklyRecap, .glossaryTerm("ketones"),
                                         .guide("ranges"), .supplies, .schoolCard]
        for route in routes {
            #expect(AppRouter.route(for: AppRouter.url(for: route)) == route)
        }
        #expect(AppRouter.route(for: URL(string: "https://example.com/trends")!) == nil)
    }

    @MainActor
    @Test func spotlightIdentifiersMapToRoutes() {
        #expect(SpotlightIndexer.route(for: "term.ketones") == .glossaryTerm("ketones"))
        #expect(SpotlightIndexer.route(for: "guide.ranges") == .guide("ranges"))
        #expect(SpotlightIndexer.route(for: "other") == nil)
    }

    @Test func glanceSnapshotFormatsAndClassifies() {
        var snapshot = GlanceSnapshot.placeholder
        snapshot.latest = GlanceSnapshot.Point(date: t0, mgdl: 180.18)
        #expect(snapshot.value(180.18) == "180")
        snapshot.unit = "mmol/L"
        #expect(snapshot.value(180.18) == "10.0")
        #expect(snapshot.zone(60) == .low)
        #expect(snapshot.zone(260) == .urgentHigh)
        #expect(snapshot.isStale(at: t0.addingTimeInterval(16 * 60)))
        #expect(!snapshot.isStale(at: t0.addingTimeInterval(5 * 60)))
    }
}

@MainActor
@Suite("Backups of new entries", .serialized)
struct NewEntryBackupTests {
    @Test func ketonesTagsAndMealPhotosRoundTrip() throws {
        let sourceURL = tempURL(".sqlite"), targetURL = tempURL(".sqlite")
        defer { removeStore(at: sourceURL); removeStore(at: targetURL) }
        let source = PersistenceController(storeURL: sourceURL)
        let context = source.container.viewContext
        let ketone = KetoneReading(context: context)
        ketone.id = UUID(); ketone.timestamp = t0; ketone.value = 1.2; ketone.method = KetoneMethod.blood.rawValue
        let tag = ContextTag(context: context)
        tag.id = UUID(); tag.timestamp = t0; tag.kind = DayTag.sick.rawValue
        let carbs = CarbEntry(context: context)
        carbs.id = UUID(); carbs.timestamp = t0; carbs.grams = 30; carbs.photo = Data([1, 2, 3])
        try context.save()

        let archive = try BackupStore.makeArchive(in: context, settings: nil, appVersion: "1", now: t0)
        #expect(archive.ketones?.count == 1)
        #expect(archive.tags?.first?.kind == "sick")
        #expect(archive.carbs.first?.photo == Data([1, 2, 3]))
        #expect(archive.entryCount == 3)

        let target = PersistenceController(storeURL: targetURL)
        let result = try BackupStore.restore(BackupArchive.decode(archive.encoded()), mode: .merge, in: target.container.viewContext)
        #expect(result.added == 3)
        let again = try BackupStore.makeArchive(in: target.container.viewContext, settings: nil, appVersion: "1", now: t0)
        #expect(again == archive)
    }

    @Test func olderBackupsWithoutNewFieldsStillRead() throws {
        let old = Data("""
        {"version":1,"exportedAt":"2027-01-15T08:00:00Z","appVersion":"1.0","glucose":[],"carbs":[{"id":"\(UUID().uuidString)","grams":20}],"insulin":[],"activity":[],"sites":[]}
        """.utf8)
        let archive = try BackupArchive.decode(old)
        #expect(archive.carbs.count == 1)
        #expect(archive.ketones == nil)
        #expect(archive.kit == nil)
    }

    @Test func familySharingLeavesPrivateExtrasOut() {
        var archive = BackupArchive(exportedAt: t0, appVersion: "1")
        archive.carbs = [BackupArchive.Carb(id: UUID(), timestamp: t0, grams: 10, photo: Data([9]))]
        archive.ketones = [BackupArchive.Ketone(id: UUID(), timestamp: t0, value: 1)]
        archive.tags = [BackupArchive.Tag(id: UUID(), timestamp: t0, kind: "sick")]
        let shared = FamilyDiff.shareable(archive, stage: .teen)
        #expect(shared.carbs.first?.photo == nil)
        #expect(shared.ketones == nil)
        #expect(shared.tags == nil)
    }
}

@MainActor
@Suite("Help replies", .serialized)
struct HelpReplyTests {
    @Test func aGrownUpsReplyReachesTheKid() async throws {
        let (kidDefaults, cleanKid) = isolatedDefaults()
        let (parentDefaults, cleanParent) = isolatedDefaults()
        defer { cleanKid(); cleanParent() }
        let transport = LoopbackFamilyTransport()

        let kidSettings = SettingsStore(defaults: kidDefaults)
        kidSettings.familySharingEnabled = true
        let kid = FamilyService(settings: kidSettings, defaults: kidDefaults, transport: transport)
        #expect(await kid.sendHelpRequest(mgdl: 62))
        #expect(await kid.checkReplies() == nil, "no reply yet")

        let parentSettings = SettingsStore(defaults: parentDefaults)
        parentSettings.userName = "Mom"
        let parent = FamilyService(settings: parentSettings, defaults: parentDefaults, transport: transport)
        await parent.refreshFollowed()
        let person = try #require(parent.followed.first)
        let request = try #require(parent.pendingHelp[person.id])
        #expect(request.mgdl == 62)

        #expect(await parent.reply(.onMyWay, to: person))
        #expect(parent.pendingHelp[person.id] == nil)

        let reply = try #require(await kid.checkReplies())
        #expect(reply.from == "Mom")
        #expect(reply.message == .onMyWay)
        #expect(kid.latestReply == reply)
        #expect(await kid.checkReplies() == nil, "the same reply isn't delivered twice")

        parent.unfollow(person)
    }
}

@Suite("Story rewording guard")
struct StoryWriterTests {
    private let template = "6 hr 40 min in range. Steadiest stretch 2:00 PM–7:00 PM. No lows. Range 82–214 mg/dL."

    @Test func keepsFaithfulRewording() {
        #expect(StoryWriter.isFaithful("Nice day! 6 hr 40 min in range, steadiest from 2:00 PM to 7:00 PM, no lows, and a range of 82–214 mg/dL.", to: template))
    }

    @Test func rejectsDroppedNumbersAndAdvice() {
        #expect(!StoryWriter.isFaithful("Great day with lots of time in range and no lows!", to: template))
        #expect(!StoryWriter.isFaithful("6 hr 40 min in range, 2:00 PM–7:00 PM steady, no lows, 82–214 mg/dL. Take more insulin tonight.", to: template))
        #expect(!StoryWriter.isFaithful("", to: template))
    }
}
