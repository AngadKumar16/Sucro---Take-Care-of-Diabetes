//
//  TimelineEvent.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import Foundation
import SwiftUI

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

struct Reminder: Identifiable {
    let id = UUID()
    let title: String
    let time: Date
    let type: ReminderType
}

enum ReminderType {
    case siteChange
    case deviceCheck
    case medication
}
