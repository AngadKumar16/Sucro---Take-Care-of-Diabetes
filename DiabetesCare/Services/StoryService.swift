//
//  StoryService.swift
//  DiabetesCare
//
//  Reads the log for the summaries on Today and the weekly recap. The math
//  lives in `Story` and `Streaks`.
//

import CoreData
import Foundation

@MainActor
enum StoryService {
    struct Today: Equatable {
        var streaks = Streaks.Value()
        /// Today so far.
        var day: Story.Day?
        var yesterday: Story.Day?
        /// Midnight to 6 a.m. today.
        var night: Story.Night?
    }

    /// Everything Today shows, from samples it already has in memory plus a
    /// few small fetches.
    static func today(samples: [GlucoseSample], context: NSManagedObjectContext, settings: SettingsStore, now: Date = Date()) -> Today {
        let calendar = Calendar.current
        let thresholds = settings.thresholds
        let startOfToday = calendar.startOfDay(for: now)
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: startOfToday) ?? startOfToday
        let carbTimes = DataService.shared
            .fetchCarbEntries(context: context, in: DateInterval(start: yesterdayStart, end: now))
            .compactMap(\.timestamp)

        var story = Today()
        story.day = Story.day(samples: samples, carbTimes: carbTimes, thresholds: thresholds,
                              in: DateInterval(start: startOfToday, end: max(startOfToday, now)))
        story.yesterday = Story.day(samples: samples, carbTimes: carbTimes, thresholds: thresholds,
                                    in: DateInterval(start: yesterdayStart, end: startOfToday))
        story.night = Story.night(samples: samples, thresholds: thresholds, now: now)
        story.streaks = streaks(context: context, settings: settings, now: now)
        return story
    }

    static func streaks(context: NSManagedObjectContext, settings: SettingsStore, now: Date = Date()) -> Streaks.Value {
        let start = Calendar.current.date(byAdding: .day, value: -400, to: now) ?? now
        let logged = loggedDates(context: context, in: DateInterval(start: start, end: now))
        let sites = ((try? context.fetch(SiteChange.fetchRequest())) ?? []).compactMap(\.rotationChange)
        return Streaks.Value(
            logging: SkillHabits.loggingStreak(entryDates: logged, now: now),
            daysWithoutUrgentLow: daysWithoutUrgentLow(context: context, thresholds: settings.thresholds, now: now),
            sitesOnTime: Streaks.sitesOnTime(sites, now: now)
        )
    }

    /// Days since the last urgent low, from two one-row fetches rather than
    /// every reading.
    private static func daysWithoutUrgentLow(context: NSManagedObjectContext, thresholds: GlucoseThresholds, now: Date) -> Int {
        let first: NSFetchRequest<GlucoseReading> = GlucoseReading.fetchRequest()
        first.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReading.timestamp, ascending: true)]
        first.fetchLimit = 1
        let lastUrgent: NSFetchRequest<GlucoseReading> = GlucoseReading.fetchRequest()
        lastUrgent.predicate = NSPredicate(format: "value < %f", thresholds.urgentLow)
        lastUrgent.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReading.timestamp, ascending: false)]
        lastUrgent.fetchLimit = 1
        let samples = [(try? context.fetch(first))?.first, (try? context.fetch(lastUrgent))?.first].compactMap { $0?.sample }
        return Streaks.daysWithoutUrgentLow(
            samples: samples,
            thresholds: thresholds,
            now: now
        )
    }

    /// When the person logged something by hand: meals, doses, activity,
    /// site changes and glucose they typed in (not CGM imports).
    static func loggedDates(context: NSManagedObjectContext, in range: DateInterval) -> [Date] {
        let inRange = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", range.start as NSDate, range.end as NSDate)
        // Only the timestamps, and never the hundreds of CGM readings a day.
        let manual = NSCompoundPredicate(andPredicateWithSubpredicates: [
            inRange, NSPredicate(format: "source == nil OR source != %@", GlucoseSource.health.rawValue)
        ])
        func timestamps(_ entity: String, _ predicate: NSPredicate) -> [Date] {
            let request = NSFetchRequest<NSDictionary>(entityName: entity)
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = ["timestamp"]
            request.predicate = predicate
            return ((try? context.fetch(request)) ?? []).compactMap { $0["timestamp"] as? Date }
        }
        return timestamps("GlucoseReading", manual)
            + timestamps("CarbEntry", inRange)
            + timestamps("InsulinEntry", inRange)
            + timestamps("ActivityEntry", inRange)
            + timestamps("SiteChange", inRange)
    }

    /// The last seven days, compared with the seven before.
    static func week(context: NSManagedObjectContext, settings: SettingsStore, now: Date = Date()) -> Story.Week? {
        let start = Calendar.current.date(byAdding: .day, value: -15, to: now) ?? now
        let range = DateInterval(start: start, end: now)
        let samples = DataService.shared.fetchGlucoseReadings(context: context, in: range).compactMap(\.sample)
        return Story.week(samples: samples, loggedDates: loggedDates(context: context, in: range), thresholds: settings.thresholds, now: now)
    }

    /// The days of the last week, newest first, each with its story.
    static func days(context: NSManagedObjectContext, settings: SettingsStore, count: Int = 7, now: Date = Date()) -> [Story.Day] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -(count - 1), to: today) ?? today
        let range = DateInterval(start: start, end: now)
        let samples = DataService.shared.fetchGlucoseReadings(context: context, in: range).compactMap(\.sample)
        let carbTimes = DataService.shared.fetchCarbEntries(context: context, in: range).compactMap(\.timestamp)
        return (0..<count).compactMap { offset in
            guard let dayStart = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let end = min(now, dayStart.addingTimeInterval(86_400))
            return Story.day(samples: samples, carbTimes: carbTimes, thresholds: settings.thresholds,
                             in: DateInterval(start: dayStart, end: max(dayStart, end)))
        }
    }
}
