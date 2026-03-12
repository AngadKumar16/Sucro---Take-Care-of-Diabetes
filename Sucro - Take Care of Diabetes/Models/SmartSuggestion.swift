//
//  SmartSuggestion.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation

enum SuggestionType: String, CaseIterable, Codable {
    case glucoseHigh = "High Glucose"
    case glucoseLow = "Low Glucose"
    case siteChange = "Site Change Due"
    case patternDetected = "Pattern Detected"
    case deviceIssue = "Device Issue"
    case medicationReminder = "Medication Reminder"
    
    var icon: String {
        switch self {
        case .glucoseHigh:
            return "arrow.up.circle.fill"
        case .glucoseLow:
            return "arrow.down.circle.fill"
        case .siteChange:
            return "bandage.fill"
        case .patternDetected:
            return "chart.line.uptrend.xyaxis"
        case .deviceIssue:
            return "exclamationmark.triangle.fill"
        case .medicationReminder:
            return "pills.fill"
        }
    }
    
    var priority: Int {
        switch self {
        case .glucoseLow, .deviceIssue:
            return 1 // High priority
        case .glucoseHigh, .siteChange:
            return 2 // Medium priority
        case .patternDetected, .medicationReminder:
            return 3 // Low priority
        }
    }
}

struct SmartSuggestion: Identifiable, Codable {
    let id = UUID()
    let title: String
    let subtitle: String
    let type: SuggestionType
    let timestamp: Date
    let isActionable: Bool
    let actionText: String?
    
    init(title: String, subtitle: String, type: SuggestionType, isActionable: Bool = true, actionText: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.type = type
        self.timestamp = Date()
        self.isActionable = isActionable
        self.actionText = actionText
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    static func highGlucose(value: Double) -> SmartSuggestion {
        return SmartSuggestion(
            title: "High Glucose Alert",
            subtitle: "Current reading is \(Int(value)) mg/dL - consider correction",
            type: .glucoseHigh,
            actionText: "Log Correction"
        )
    }
    
    static func lowGlucose(value: Double) -> SmartSuggestion {
        return SmartSuggestion(
            title: "Low Glucose Alert", 
            subtitle: "Current reading is \(Int(value)) mg/dL - treat immediately",
            type: .glucoseLow,
            actionText: "Treat Now"
        )
    }
    
    static func siteChangeDue(daysSinceChange: Int) -> SmartSuggestion {
        return SmartSuggestion(
            title: "Site Change Recommended",
            subtitle: "\(daysSinceChange) days since last change",
            type: .siteChange,
            actionText: "Change Site"
        )
    }
}
