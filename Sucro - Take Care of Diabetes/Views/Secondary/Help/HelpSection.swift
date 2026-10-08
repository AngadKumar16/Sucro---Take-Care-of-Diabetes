//
//  HelpSection.swift
//  Sucro - Take Care of Diabetes
//

import Foundation

enum HelpSection: String, CaseIterable {
    case gettingStarted = "Getting Started"
    case logging = "Logging Data"
    case cgm = "Devices & Apple Health"
    case insights = "Understanding Insights"
    case emergency = "Emergency Help"

    var icon: String {
        switch self {
        case .gettingStarted: return "star.fill"
        case .logging: return "square.and.pencil"
        case .cgm: return "heart.text.square"
        case .insights: return "chart.bar.fill"
        case .emergency: return "cross.case.fill"
        }
    }

    var content: String {
        switch self {
        case .gettingStarted:
            return "Today shows your latest glucose, how much insulin is still active, and shortcuts for common entries. Log lists everything you've recorded, day by day, and the + button adds readings, meals, insulin and activity. Trends charts your glucose over time, and Reports makes a PDF for your care team."
        case .logging:
            return "The Log Meal, Quick Bolus, and Change Site buttons on Today are the fastest way to log. Touch and hold Log Meal to pick a saved meal. Every form has a Time field, so you can log something you forgot earlier. In the Log tab, tap an entry to edit it or swipe left to delete it. DiabetesCare also saves what you log to Apple Health."
        case .cgm:
            return "DiabetesCare can't connect to a CGM or pump directly yet, so log readings and doses yourself. What you log is saved to Apple Health. To check that, open Settings › Devices & Apple Health."
        case .insights:
            return "Insights shows whether your average glucose is going up or down, which meals are followed by big rises, and your time in range. Time in range is the share of readings between the target low and high you set in Settings."
        case .emergency:
            return "For a low, eat 15g of fast-acting carbs and check again after 15 minutes. If someone is unconscious, a caregiver should give glucagon and call emergency services. You can open your Medical ID from Settings › Help › Emergency Medical ID."
        }
    }
}
