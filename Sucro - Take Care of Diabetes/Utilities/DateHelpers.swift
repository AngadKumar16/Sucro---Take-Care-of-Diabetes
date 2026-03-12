//
//  DateHelpers.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//


//
//  DateHelpers.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation

struct DateHelpers {
    
    // MARK: - Formatters
    
    static let shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    // MARK: - Date Calculations
    
    static func startOfDay(_ date: Date = Date()) -> Date {
        return Calendar.current.startOfDay(for: date)
    }
    
    static func endOfDay(_ date: Date = Date()) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay(date))!
    }
    
    static func daysBetween(_ start: Date, _ end: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }
    
    static func hoursBetween(_ start: Date, _ end: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour], from: start, to: end)
        return components.hour ?? 0
    }
    
    static func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }
    
    static func isYesterday(_ date: Date) -> Bool {
        return Calendar.current.isDateInYesterday(date)
    }
    
    // MARK: - Time Ago Strings
    
    static func timeAgoString(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return days == 1 ? "Yesterday" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else {
            return "Just now"
        }
    }
    
    // MARK: - Date Ranges
    
    static func last24Hours() -> DateInterval {
        let end = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -24, to: end)!
        return DateInterval(start: start, end: end)
    }
    
    static func last7Days() -> DateInterval {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -7, to: end)!
        return DateInterval(start: start, end: end)
    }
    
    static func last30Days() -> DateInterval {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -30, to: end)!
        return DateInterval(start: start, end: end)
    }
}