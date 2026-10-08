//
//  TimeRange.swift
//  Sucro - Take Care of Diabetes
//

import Foundation

/// How far back a chart, statistic or report looks. Trends and Reports
/// offer different subsets but share these names.
nonisolated enum TimeRange: String, CaseIterable, Sendable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case quarter = "3 Months"
    case year = "Year"

    static let trends: [TimeRange] = [.day, .week, .month, .quarter]
    static let reports: [TimeRange] = [.week, .month, .quarter, .year]

    var days: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        }
    }

    /// The interval ending at `end` that this range covers.
    func interval(endingAt end: Date = Date()) -> DateInterval {
        DateInterval(start: end.addingTimeInterval(-Double(days) * 86_400), end: end)
    }
}
