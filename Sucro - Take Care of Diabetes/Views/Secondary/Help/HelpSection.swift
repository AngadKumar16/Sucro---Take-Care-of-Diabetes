//
//  HelpSection.swift
//  Sucro - Take Care of Diabetes
//

import Foundation

enum HelpSection: String, CaseIterable {
    case gettingStarted = "Getting Started"
    case logging = "Logging Data"
    case cgm = "CGM & Devices"
    case insights = "Understanding Insights"
    case emergency = "Emergency Help"

    var icon: String {
        switch self {
        case .gettingStarted: return "star.fill"
        case .logging: return "square.and.pencil"
        case .cgm: return "wifi"
        case .insights: return "chart.bar.fill"
        case .emergency: return "cross.case.fill"
        }
    }

    var content: String {
        switch self {
        case .gettingStarted:
            return "Home shows your latest glucose, how much insulin is still active, and shortcuts for common entries. Log is where you record readings, meals, insulin, and activity. Monitor charts your glucose over time."
        case .logging:
            return "The Log Meal, Quick Bolus, and Change Site buttons on Home are the fastest way to log. For more detail, use the Log tab. Press and hold Log Meal to pick a saved meal. Sucro also saves what you log to Apple Health."
        case .cgm:
            return "Connect and disconnect devices from the Devices screen. That's also where you turn Auto-sync, Background Monitoring, and Low Battery Alerts on or off. If a device stops sending data, follow the troubleshooting steps to reconnect it."
        case .insights:
            return "Insights shows whether your average glucose is going up or down, which meals are followed by big rises, and your time in range. Time in range is the share of readings between the target low and high you set in Settings."
        case .emergency:
            return "For a low, eat 15g of fast-acting carbs and check again after 15 minutes. If someone is unconscious, a caregiver should give glucagon and call emergency services. You can open your Medical ID from Help > Emergency Medical ID."
        }
    }
}
