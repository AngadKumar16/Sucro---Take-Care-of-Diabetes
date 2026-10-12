//
//  Skill.swift
//  DiabetesCare
//
//  The skills that make growing up visible. Four are short checks after a
//  Learn guide; two are habits the app notices in the log. Finishing them
//  opens features early and shows when someone is ready for the next
//  stage. Skills are knowledge and habits only, never dosing.
//

import Foundation

nonisolated enum Skill: String, Codable, CaseIterable, Identifiable, Sendable {
    case ranges
    case treatingLows
    case units
    case timeInRange
    case steadyLogger
    case lowRecovery

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ranges: String(localized: "Know Your Ranges")
        case .treatingLows: String(localized: "Treat a Low")
        case .units: String(localized: "Read the Numbers")
        case .timeInRange: String(localized: "Time in Range")
        case .steadyLogger: String(localized: "Steady Logger")
        case .lowRecovery: String(localized: "Low, Treated, Checked")
        }
    }

    var summary: String {
        switch self {
        case .ranges: String(localized: "What low, in range and high mean, and what to do.")
        case .treatingLows: String(localized: "The rule of 15, step by step.")
        case .units: String(localized: "mg/dL, mmol/L and what a number tells you.")
        case .timeInRange: String(localized: "The daily goal and why lows come first.")
        case .steadyLogger: String(localized: "Log something every day for 7 days in a row.")
        case .lowRecovery: String(localized: "Treat a low with carbs, then check again within 40 minutes.")
        }
    }

    var symbol: String {
        switch self {
        case .ranges: "ruler.fill"
        case .treatingLows: "cube.fill"
        case .units: "arrow.left.arrow.right"
        case .timeInRange: "chart.bar.fill"
        case .steadyLogger: "calendar"
        case .lowRecovery: "arrow.uturn.up"
        }
    }

    /// The Learn guide a quiz skill checks.
    var guide: Guide? {
        switch self {
        case .ranges: .ranges
        case .treatingLows: .treatingLows
        case .units: .units
        case .timeInRange: .timeInRange
        case .steadyLogger, .lowRecovery: nil
        }
    }

    var isQuiz: Bool { guide != nil }

    /// The skills that open a parent-locked feature early at a stage.
    static func unlocking(_ feature: Feature, at stage: CareStage) -> [Skill]? {
        switch (stage, feature) {
        case (.kid, .logInsulin): [.ranges, .treatingLows]
        case (.kid, .changeSite): [.steadyLogger]
        default: nil
        }
    }

    /// What finishing this skill opens up at a stage, for the path screen.
    func unlocks(at stage: CareStage) -> [Feature] {
        Feature.allCases.filter { Skill.unlocking($0, at: stage)?.contains(self) == true }
    }
}

// MARK: - Quizzes

nonisolated struct QuizQuestion: Identifiable, Sendable {
    let id: Int
    let prompt: String
    let options: [String]
    let answer: Int
    /// Shown after answering, right or wrong.
    let explanation: String
}

extension Skill {
    /// Three questions that match what the guide teaches. All of them must
    /// be right to pass; it can be retaken any time.
    var questions: [QuizQuestion] {
        switch self {
        case .ranges:
            [
                QuizQuestion(id: 0,
                             prompt: String(localized: "Your glucose is below your Low line. What does that mean?"),
                             options: [String(localized: "Nothing, wait and see"), String(localized: "You're low and need to act now"), String(localized: "You're in range")],
                             answer: 1,
                             explanation: String(localized: "Below Low means act now: treat with fast-acting carbs and check again.")),
                QuizQuestion(id: 1,
                             prompt: String(localized: "Who should help you decide where your lines are?"),
                             options: [String(localized: "Your care team"), String(localized: "Friends at school"), String(localized: "The app picks for you")],
                             answer: 0,
                             explanation: String(localized: "Targets differ by person and age, so set them with your care team.")),
                QuizQuestion(id: 2,
                             prompt: String(localized: "Your glucose is above Urgent High. What should you check for?"),
                             options: [String(localized: "Ketones"), String(localized: "Your shoe size"), String(localized: "Nothing")],
                             answer: 0,
                             explanation: String(localized: "Very high glucose can come with ketones. Check, and follow your care team's plan.")),
            ]
        case .treatingLows:
            [
                QuizQuestion(id: 0,
                             prompt: String(localized: "How many grams of fast-acting carbs does the rule of 15 start with?"),
                             options: [String(localized: "5 g"), String(localized: "15 g"), String(localized: "50 g")],
                             answer: 1,
                             explanation: String(localized: "15 g of fast-acting carbs, like juice or glucose tablets. Your care team may give you a different amount.")),
                QuizQuestion(id: 1,
                             prompt: String(localized: "After treating a low, when do you check again?"),
                             options: [String(localized: "Tomorrow"), String(localized: "In about 15 minutes"), String(localized: "Only if you feel bad")],
                             answer: 1,
                             explanation: String(localized: "Check again in 15 minutes. Still low? Treat again.")),
                QuizQuestion(id: 2,
                             prompt: String(localized: "Someone is too confused to swallow safely. What do you do?"),
                             options: [String(localized: "Give them juice anyway"), String(localized: "Let them sleep"), String(localized: "No food or drink: use glucagon if they have it and call emergency services")],
                             answer: 2,
                             explanation: String(localized: "Never give food or drink to someone who can't swallow safely. Glucagon and emergency services.")),
            ]
        case .units:
            [
                QuizQuestion(id: 0,
                             prompt: String(localized: "The US mostly measures glucose in…"),
                             options: [String(localized: "mg/dL"), String(localized: "mmol/L"), String(localized: "Grams")],
                             answer: 0,
                             explanation: String(localized: "The US mostly uses mg/dL. Many other countries use mmol/L.")),
                QuizQuestion(id: 1,
                             prompt: String(localized: "About how much is 5.5 mmol/L in mg/dL?"),
                             options: [String(localized: "55"), String(localized: "100"), String(localized: "550")],
                             answer: 1,
                             explanation: String(localized: "Multiply mmol/L by about 18: 5.5 × 18 ≈ 100 mg/dL.")),
                QuizQuestion(id: 2,
                             prompt: String(localized: "Does switching units in Settings change your data?"),
                             options: [String(localized: "Yes, it rewrites every reading"), String(localized: "No, it only changes how numbers are shown")],
                             answer: 1,
                             explanation: String(localized: "DiabetesCare stores mg/dL and converts only for display.")),
            ]
        case .timeInRange:
            [
                QuizQuestion(id: 0,
                             prompt: String(localized: "A common time-in-range goal for many adults is more than…"),
                             options: [String(localized: "30%"), String(localized: "50%"), String(localized: "70%")],
                             answer: 2,
                             explanation: String(localized: "More than 70%, about 17 hours a day. Goals differ for kids, so ask your care team.")),
                QuizQuestion(id: 1,
                             prompt: String(localized: "What matters most to cut first?"),
                             options: [String(localized: "Time below range (lows)"), String(localized: "Time in range"), String(localized: "Neither")],
                             answer: 0,
                             explanation: String(localized: "Lows come first: cutting time below range matters most.")),
                QuizQuestion(id: 2,
                             prompt: String(localized: "About how much time is each extra 5% in range?"),
                             options: [String(localized: "5 minutes"), String(localized: "About 72 minutes a day"), String(localized: "5 hours")],
                             answer: 1,
                             explanation: String(localized: "5% of 24 hours is about 72 minutes, and it makes a real difference.")),
            ]
        case .steadyLogger, .lowRecovery:
            []
        }
    }
}

// MARK: - Habits

/// Spots the habit skills in the log. Pure, so it can be tested.
nonisolated enum SkillHabits {
    /// Days in a row, ending today or yesterday, with at least one entry the
    /// person logged themselves.
    static func loggingStreak(entryDates: [Date], now: Date, calendar: Calendar = .current) -> Int {
        let days = Set(entryDates.map { calendar.startOfDay(for: $0) })
        var day = calendar.startOfDay(for: now)
        if !days.contains(day), let yesterday = calendar.date(byAdding: .day, value: -1, to: day) {
            day = yesterday
        }
        var streak = 0
        while days.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    static let streakGoal = 7

    /// A low reading, carbs logged within 20 minutes after it, and a reading
    /// back at or above the Low line within 40 minutes of the carbs.
    static func hasRecoveredFromLow(readings: [GlucoseSample], carbTimes: [Date], thresholds: GlucoseThresholds) -> Bool {
        let sorted = readings.sorted { $0.date < $1.date }
        for low in sorted where thresholds.zone(for: low.mgdl).isLow {
            let treatments = carbTimes.filter { $0 >= low.date && $0.timeIntervalSince(low.date) <= 20 * 60 }
            for carbs in treatments {
                let recovered = sorted.contains { reading in
                    reading.date > carbs
                        && reading.date.timeIntervalSince(carbs) <= 40 * 60
                        && reading.mgdl >= thresholds.targetLow
                }
                if recovered { return true }
            }
        }
        return false
    }
}
