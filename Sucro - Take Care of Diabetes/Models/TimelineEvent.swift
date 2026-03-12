//
//  TimelineEvent.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import Foundation
import SwiftUI
import Combine  // ADD THIS

struct TimelineEvent: Identifiable {
    let id = UUID()
    let type: EventType
    let timestamp: Date
    let glucoseValue: Double
    let title: String
    let subtitle: String?
    
    var icon: String {
        switch type {
        case .meal:
            return "fork.knife"
        case .bolus:
            return "syringe"
        case .siteChange:
            return "bandage"
        case .activity:
            return "figure.walk"
        }
    }
    
    var color: Color {
        switch type {
        case .meal:
            return .orange
        case .bolus:
            return .green
        case .siteChange:
            return .purple
        case .activity:
            return .blue
        }
    }
}

enum EventType {
    case meal
    case bolus
    case siteChange
    case activity
}

// REMOVE THESE - They are already defined in Data/Models/Domain/Reminder.swift and Data/Models/Enums/ReminderType.swift
// struct Reminder: Identifiable { ... }
// enum ReminderType { ... }
