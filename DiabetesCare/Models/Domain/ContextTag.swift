//
//  ContextTag.swift
//  DiabetesCare
//
//  What kind of day it was: sick, stressed, sports, a period, a party,
//  travel. Tagged on Today, compared on Trends ("higher on sick days").
//

import CoreData
import Foundation

@objc(ContextTag)
public class ContextTag: NSManagedObject {
    @NSManaged public var id: UUID?
    /// Any time on the day it applies to.
    @NSManaged public var timestamp: Date?
    @NSManaged public var kind: String?
    @NSManaged public var notes: String?
}

extension ContextTag {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ContextTag> {
        NSFetchRequest<ContextTag>(entityName: "ContextTag")
    }

    var tagKind: DayTag? { DayTag(rawValue: kind ?? "") }
}

extension ContextTag: Identifiable {}

nonisolated enum DayTag: String, CaseIterable, Identifiable, Sendable {
    case sick, stress, sports, period, party, travel

    var id: String { rawValue }

    var name: String {
        switch self {
        case .sick: String(localized: "Sick")
        case .stress: String(localized: "Stressed")
        case .sports: String(localized: "Sports")
        case .period: String(localized: "Period")
        case .party: String(localized: "Party")
        case .travel: String(localized: "Travel")
        }
    }

    var symbol: String {
        switch self {
        case .sick: "thermometer.medium"
        case .stress: "brain.head.profile"
        case .sports: "figure.run"
        case .period: "drop.circle"
        case .party: "party.popper"
        case .travel: "airplane"
        }
    }
}

/// Glucose on tagged days against the rest.
nonisolated enum TagInsights {
    struct Comparison: Equatable, Sendable {
        var tag: DayTag
        var days: Int
        var average: Double
        var otherAverage: Double
        var inRangePercent: Double
        var otherInRangePercent: Double
    }

    /// One comparison per tag used on at least `minimumDays` days with
    /// readings, when there are untagged days to compare with.
    static func compare(samples: [GlucoseSample], tags: [(DayTag, Date)], thresholds: GlucoseThresholds,
                        minimumDays: Int = 2, calendar: Calendar = .current) -> [Comparison] {
        let byDay = Dictionary(grouping: samples) { calendar.startOfDay(for: $0.date) }
        var results: [Comparison] = []
        for tag in DayTag.allCases {
            let days = Set(tags.filter { $0.0 == tag }.map { calendar.startOfDay(for: $0.1) })
            let tagged = days.flatMap { byDay[$0] ?? [] }
            let taggedDays = days.count { byDay[$0] != nil }
            let others = byDay.filter { !days.contains($0.key) }.flatMap(\.value)
            guard taggedDays >= minimumDays, !tagged.isEmpty, !others.isEmpty else { continue }
            func inRange(_ s: [GlucoseSample]) -> Double {
                Double(s.count { thresholds.zone(for: $0.mgdl) == .inRange }) / Double(s.count) * 100
            }
            results.append(Comparison(
                tag: tag,
                days: taggedDays,
                average: GlucoseCalculator.calculateAverage(samples: tagged),
                otherAverage: GlucoseCalculator.calculateAverage(samples: others),
                inRangePercent: inRange(tagged),
                otherInRangePercent: inRange(others)
            ))
        }
        return results
    }
}
