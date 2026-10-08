//
//  TimelineEvent.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import CoreData
import SwiftUI

struct TimelineEvent: Identifiable {
    let id = UUID()
    let type: EventType
    let timestamp: Date
    /// Glucose around the time of the event, if a reading was logged.
    let glucoseValue: Double?
    let title: String
    let subtitle: String?
    var notes: String? = nil
    /// The Core Data entry behind the event, so edits and deletes hit
    /// exactly that entry. `nil` only in previews.
    var objectID: NSManagedObjectID? = nil
    
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
