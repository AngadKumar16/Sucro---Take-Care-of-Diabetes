//
//  Formatters.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//


//
//  Formatters.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation

struct Formatters {
    
    // MARK: - Number Formatters
    
    static let glucoseFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    static let insulinFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        return formatter
    }()
    
    static let carbFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    static let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    // MARK: - Date Formatters
    
    static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    // MARK: - Convenience Methods
    
    static func formatGlucose(_ value: Double) -> String {
        return glucoseFormatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
    
    static func formatInsulin(_ units: Double) -> String {
        return insulinFormatter.string(from: NSNumber(value: units)) ?? "\(units)"
    }
    
    static func formatCarbs(_ grams: Double) -> String {
        return carbFormatter.string(from: NSNumber(value: grams)) ?? "\(Int(grams))"
    }
    
    static func formatPercentage(_ value: Double) -> String {
        return percentageFormatter.string(from: NSNumber(value: value / 100)) ?? "\(Int(value))%"
    }
}