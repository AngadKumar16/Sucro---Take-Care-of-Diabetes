//
//  SkillProgress.swift
//  DiabetesCare
//
//  Reads the log for the habit skills and marks them done once earned.
//  The rules themselves are in `SkillHabits`.
//

import CoreData
import Foundation

@MainActor
enum SkillProgress {
    struct Snapshot: Equatable {
        var streak = 0
        var recoveredFromLow = false
        /// Habit skills this refresh marked done for the first time.
        var newlyEarned: [Skill] = []
    }

    /// Looks at the last 30 days, marks any habit skill earned, and returns
    /// the numbers the path screen shows.
    @discardableResult
    static func refresh(context: NSManagedObjectContext, settings: SettingsStore, now: Date = Date()) -> Snapshot {
        let start = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        let range = DateInterval(start: start, end: now)
        let data = DataService.shared

        // Readings a CGM sends through Apple Health don't count as logging.
        let readings = data.fetchGlucoseReadings(context: context, in: range)
        let manualDates = readings.filter { !$0.isFromHealth }.compactMap(\.timestamp)
        let carbs = data.fetchCarbEntries(context: context, in: range)
        let carbDates = carbs.compactMap(\.timestamp)
        let insulinDates = data.fetchInsulinEntries(context: context, in: range).compactMap(\.timestamp)

        var snapshot = Snapshot(
            streak: SkillHabits.loggingStreak(entryDates: manualDates + carbDates + insulinDates, now: now),
            recoveredFromLow: SkillHabits.hasRecoveredFromLow(
                readings: readings.compactMap(\.sample),
                carbTimes: carbDates,
                thresholds: settings.thresholds
            )
        )
        let before = settings.completedSkills
        if snapshot.streak >= SkillHabits.streakGoal { settings.complete(.steadyLogger) }
        if snapshot.recoveredFromLow { settings.complete(.lowRecovery) }
        snapshot.newlyEarned = Skill.allCases.filter { settings.completedSkills.contains($0) && !before.contains($0) }
        return snapshot
    }
}
