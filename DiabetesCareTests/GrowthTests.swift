//
//  GrowthTests.swift
//  DiabetesCare Tests
//
//  Covers "grows with you": what each stage can do, skills that open
//  features early, readiness to move up, the grown-up passcode, and the
//  habit skills read from the log.
//

import Testing
import Foundation
@testable import DiabetesCare

private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

@Suite("Stages")
struct StageTests {
    @Test func adultHasEverythingOpen() {
        for feature in Feature.allCases {
            #expect(CareStage.adult.access(to: feature) == .open)
        }
    }

    @Test func kidNeedsAGrownUpForDosesAndSettings() {
        #expect(CareStage.kid.access(to: .quickBolus) == .hidden)
        for feature in [Feature.logInsulin, .changeSite, .editThresholds, .editInsulinSettings, .clearData, .restoreBackup, .changeStage, .stopSharing, .turnOffNotifications] {
            #expect(CareStage.kid.access(to: feature) == .parent, "\(feature)")
        }
    }

    @Test func teenLogsAloneButNotRiskySettings() {
        for feature in [Feature.logInsulin, .quickBolus, .changeSite, .editInsulinSettings] {
            #expect(CareStage.teen.access(to: feature) == .open, "\(feature)")
        }
        for feature in [Feature.editThresholds, .clearData, .restoreBackup, .changeStage, .stopSharing, .turnOffNotifications] {
            #expect(CareStage.teen.access(to: feature) == .parent, "\(feature)")
        }
    }

    @Test func skillsOpenKidFeaturesEarly() {
        #expect(CareStage.kid.access(to: .logInsulin, completed: [.ranges]) == .parent)
        #expect(CareStage.kid.access(to: .logInsulin, completed: [.ranges, .treatingLows]) == .open)
        #expect(CareStage.kid.access(to: .changeSite, completed: [.steadyLogger]) == .open)
        // Skills never open a hidden feature or a risky setting.
        #expect(CareStage.kid.access(to: .quickBolus, completed: Set(Skill.allCases)) == .hidden)
        #expect(CareStage.kid.access(to: .editThresholds, completed: Set(Skill.allCases)) == .parent)
    }

    @Test func readyToMoveUp() {
        let quizzes = Set(Skill.allCases.filter(\.isQuiz))
        #expect(!CareStage.kid.isReadyToMoveUp(completed: []))
        #expect(CareStage.kid.isReadyToMoveUp(completed: quizzes))
        #expect(!CareStage.teen.isReadyToMoveUp(completed: quizzes))
        #expect(CareStage.teen.isReadyToMoveUp(completed: Set(Skill.allCases)))
        #expect(!CareStage.adult.isReadyToMoveUp(completed: Set(Skill.allCases)))
    }

    @Test func everyQuizHasThreeAnswerableQuestions() {
        for skill in Skill.allCases where skill.isQuiz {
            #expect(skill.questions.count == 3, "\(skill)")
            for question in skill.questions {
                #expect(question.options.indices.contains(question.answer), "\(skill) \(question.id)")
            }
        }
        #expect(Skill.steadyLogger.questions.isEmpty)
    }

    @MainActor
    @Test func settingsPersistStageAndSkills() {
        let name = "GrowthTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = SettingsStore(defaults: defaults)
        #expect(settings.careStage == nil)
        #expect(settings.stage == .adult)
        #expect(!settings.hasChosenSetup)
        settings.careStage = .kid
        settings.complete(.ranges)
        settings.familySharingEnabled = true

        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.careStage == .kid)
        #expect(reloaded.completedSkills == [.ranges])
        #expect(reloaded.familySharingEnabled)
        #expect(reloaded.hasChosenSetup)
        #expect(reloaded.access(to: .quickBolus) == .hidden)
    }
}

@MainActor
@Suite("Parent lock")
struct ParentLockTests {
    @Test func setAndVerify() {
        let lock = ParentLock(storage: MemoryParentLockStorage())
        #expect(!lock.hasPasscode)
        lock.setPasscode("2468", now: t0)
        #expect(lock.hasPasscode)
        #expect(lock.isUnlocked(now: t0))
        #expect(!lock.isUnlocked(now: t0.addingTimeInterval(ParentLock.unlockDuration + 1)))

        lock.lock()
        #expect(!lock.verify("1111", now: t0))
        #expect(!lock.isUnlocked(now: t0))
        #expect(lock.verify("2468", now: t0))
        #expect(lock.isUnlocked(now: t0))
    }

    @Test func storesOnlyAHash() {
        let storage = MemoryParentLockStorage()
        let lock = ParentLock(storage: storage)
        lock.setPasscode("2468")
        let stored = storage.read() ?? Data()
        #expect(!stored.isEmpty)
        #expect(stored.range(of: Data("2468".utf8)) == nil)
    }

    @Test func rejectsBadCodes() {
        let lock = ParentLock(storage: MemoryParentLockStorage())
        lock.setPasscode("12a4")
        lock.setPasscode("123")
        #expect(!lock.hasPasscode)
    }

    @Test func locksOutAfterTooManyTries() {
        let lock = ParentLock(storage: MemoryParentLockStorage())
        lock.setPasscode("2468", now: t0)
        lock.lock()
        for _ in 0..<ParentLock.maxAttempts { lock.verify("0000", now: t0) }
        #expect(lock.isLockedOut(now: t0))
        #expect(!lock.verify("2468", now: t0))
        let later = t0.addingTimeInterval(ParentLock.lockoutDuration + 1)
        #expect(lock.verify("2468", now: later))
    }

    @Test func survivesRelaunch() {
        let storage = MemoryParentLockStorage()
        ParentLock(storage: storage).setPasscode("2468")
        let relaunched = ParentLock(storage: storage)
        #expect(relaunched.hasPasscode)
        #expect(!relaunched.isUnlocked())
        #expect(relaunched.verify("2468"))
    }

    @Test func gateRunsOpenActionsAndAsksForLockedOnes() {
        let name = "GateTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = SettingsStore(defaults: defaults)
        settings.careStage = .teen
        let lock = ParentLock(storage: MemoryParentLockStorage())
        lock.setPasscode("2468")
        lock.lock()
        let gate = ParentGate(settings: settings, lock: lock)

        var ran = 0
        gate.run(.quickBolus) { ran += 1 }
        #expect(ran == 1)
        #expect(gate.request == nil)

        gate.run(.clearData) { ran += 1 }
        #expect(ran == 1)
        #expect(gate.request?.feature == .clearData)

        gate.request = nil
        lock.verify("2468")
        gate.run(.clearData) { ran += 1 }
        #expect(ran == 2)
    }
}

@Suite("Habit skills")
struct HabitTests {
    let calendar = Calendar(identifier: .gregorian)

    @Test func streakCountsConsecutiveDays() {
        let days = (0..<7).map { t0.addingTimeInterval(-Double($0) * 86_400) }
        #expect(SkillHabits.loggingStreak(entryDates: days, now: t0, calendar: calendar) == 7)
        // A gap breaks it.
        let gap = days.filter { $0 != days[3] }
        #expect(SkillHabits.loggingStreak(entryDates: gap, now: t0, calendar: calendar) == 3)
        // Nothing yet today still counts yesterday's streak.
        #expect(SkillHabits.loggingStreak(entryDates: Array(days.dropFirst()), now: t0, calendar: calendar) == 6)
        #expect(SkillHabits.loggingStreak(entryDates: [], now: t0, calendar: calendar) == 0)
    }

    @Test func lowTreatedAndRechecked() {
        let thresholds = GlucoseThresholds.standard
        let low = GlucoseSample(date: t0, mgdl: 62)
        let carbs = t0.addingTimeInterval(5 * 60)
        let back = GlucoseSample(date: t0.addingTimeInterval(25 * 60), mgdl: 95)
        #expect(SkillHabits.hasRecoveredFromLow(readings: [low, back], carbTimes: [carbs], thresholds: thresholds))
        // No carbs, or no recheck, or still low: not yet.
        #expect(!SkillHabits.hasRecoveredFromLow(readings: [low, back], carbTimes: [], thresholds: thresholds))
        #expect(!SkillHabits.hasRecoveredFromLow(readings: [low], carbTimes: [carbs], thresholds: thresholds))
        let stillLow = GlucoseSample(date: t0.addingTimeInterval(25 * 60), mgdl: 65)
        #expect(!SkillHabits.hasRecoveredFromLow(readings: [low, stillLow], carbTimes: [carbs], thresholds: thresholds))
        // A recheck hours later doesn't count.
        let late = GlucoseSample(date: t0.addingTimeInterval(3 * 3600), mgdl: 110)
        #expect(!SkillHabits.hasRecoveredFromLow(readings: [low, late], carbTimes: [carbs], thresholds: thresholds))
    }
}
