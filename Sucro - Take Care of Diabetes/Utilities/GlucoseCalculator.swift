//
//  GlucoseCalculator.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation
import Combine

// Import your app's module to access GlucoseTrend enum
// If your app target is named "Sucro", use: import Sucro

class GlucoseCalculator {
    
    // MARK: - Insulin on Board (IOB)
    static func calculateIOB(insulinEntries: [InsulinEntry], currentTime: Date = Date()) -> Double {
        let fourHoursAgo = currentTime.addingTimeInterval(-4 * 3600)
        
        return insulinEntries
            .filter { entry in
                guard let timestamp = entry.timestamp else { return false }
                return timestamp >= fourHoursAgo && entry.type == "bolus"
            }
            .reduce(0.0) { total, entry in
                guard let timestamp = entry.timestamp else { return total }
                let hoursAgo = currentTime.timeIntervalSince(timestamp) / 3600
                let remaining = entry.units * max(0, 1 - (hoursAgo / 4))
                return total + remaining
            }
    }
    
    // MARK: - Time in Range (TIR)
    static func calculateTimeInRange(readings: [GlucoseReading], targetMin: Double = 70, targetMax: Double = 180) -> (percentage: Double, hours: Double) {
        guard !readings.isEmpty else { return (percentage: 0, hours: 0) }
        
        let inRangeCount = readings.filter { reading in
            reading.value >= targetMin && reading.value <= targetMax
        }.count
        
        let percentage = (Double(inRangeCount) / Double(readings.count)) * 100
        
        let timeSpan = calculateTimeSpan(readings: readings)
        let hoursInRange = timeSpan * (percentage / 100)
        
        return (percentage: percentage, hours: hoursInRange)
    }
    
    static func calculateTimeBelowRange(readings: [GlucoseReading], targetMin: Double = 70) -> (percentage: Double, hours: Double) {
        guard !readings.isEmpty else { return (percentage: 0, hours: 0) }
        
        let belowRangeCount = readings.filter { $0.value < targetMin }.count
        let percentage = (Double(belowRangeCount) / Double(readings.count)) * 100
        
        let timeSpan = calculateTimeSpan(readings: readings)
        let hoursBelowRange = timeSpan * (percentage / 100)
        
        return (percentage: percentage, hours: hoursBelowRange)
    }
    
    static func calculateTimeAboveRange(readings: [GlucoseReading], targetMax: Double = 180) -> (percentage: Double, hours: Double) {
        guard !readings.isEmpty else { return (percentage: 0, hours: 0) }
        
        let aboveRangeCount = readings.filter { $0.value > targetMax }.count
        let percentage = (Double(aboveRangeCount) / Double(readings.count)) * 100
        
        let timeSpan = calculateTimeSpan(readings: readings)
        let hoursAboveRange = timeSpan * (percentage / 100)
        
        return (percentage: percentage, hours: hoursAboveRange)
    }
    
    // MARK: - Average and Variability
    static func calculateAverage(readings: [GlucoseReading]) -> Double {
        guard !readings.isEmpty else { return 0 }
        return readings.reduce(0) { $0 + $1.value } / Double(readings.count)
    }
    
    static func calculateStandardDeviation(readings: [GlucoseReading]) -> Double {
        guard !readings.isEmpty else { return 0 }
        
        let average = calculateAverage(readings: readings)
        let squaredDifferences = readings.map { pow($0.value - average, 2) }
        let variance = squaredDifferences.reduce(0, +) / Double(readings.count)
        
        return sqrt(variance)
    }
    
    static func calculateCV(readings: [GlucoseReading]) -> Double {
        guard !readings.isEmpty else { return 0 }
        
        let average = calculateAverage(readings: readings)
        let standardDeviation = calculateStandardDeviation(readings: readings)
        
        return (standardDeviation / average) * 100
    }
    
    // MARK: - Glucose Trend
    // Use GlucoseTrend directly - it's in the same module (Data/Models/Enums/)
    static func calculateTrend(readings: [GlucoseReading]) -> GlucoseTrend {
        guard readings.count >= 2 else { return .stable }
        
        let recent = Array(readings.prefix(3))
        guard recent.count == 3 else { return .stable }
        
        let values = recent.map { $0.value }
        let firstValue = values[0]
        let lastValue = values[values.count - 1]
        let change = lastValue - firstValue
        
        let percentChange = (change / firstValue) * 100
        
        switch percentChange {
        case let change where change > 10:
            return .rising
        case let change where change < -10:
            return .falling
        default:
            return .stable
        }
    }
    
    // MARK: - Helper Methods
    private static func calculateTimeSpan(readings: [GlucoseReading]) -> Double {
        guard let firstTimestamp = readings.first?.timestamp,
              let lastTimestamp = readings.last?.timestamp else { return 0 }
        
        return lastTimestamp.timeIntervalSince(firstTimestamp) / 3600
    }
}

// REMOVE THIS ENTIRE ENUM - it's duplicated in Data/Models/Enums/GlucoseTrend.swift
// enum GlucoseTrend: String, CaseIterable {
//     case rising = "rising"
//     case falling = "falling"
//     case stable = "stable"
//     ...
// }
