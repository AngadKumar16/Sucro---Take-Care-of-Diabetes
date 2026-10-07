//
//  GlucoseStatistics.swift
//  Sucro - Take Care of Diabetes
//

import Foundation

nonisolated struct GlucoseStatistics: Sendable {
    let average: Double
    let standardDeviation: Double
    let cv: Double
    let timeInRange: (percentage: Double, hours: Double)
    let timeBelowRange: (percentage: Double, hours: Double)
    let timeAboveRange: (percentage: Double, hours: Double)

    init(average: Double = 0, standardDeviation: Double = 0, cv: Double = 0,
         timeInRange: (percentage: Double, hours: Double) = (percentage: 0, hours: 0),
         timeBelowRange: (percentage: Double, hours: Double) = (percentage: 0, hours: 0),
         timeAboveRange: (percentage: Double, hours: Double) = (percentage: 0, hours: 0)) {
        self.average = average
        self.standardDeviation = standardDeviation
        self.cv = cv
        self.timeInRange = timeInRange
        self.timeBelowRange = timeBelowRange
        self.timeAboveRange = timeAboveRange
    }
}
