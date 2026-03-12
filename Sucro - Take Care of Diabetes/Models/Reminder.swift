//
//  Reminder.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation

enum ReminderType: String, CaseIterable, Codable {
    case siteChange = "Site Change"
    case deviceCheck = "Device Check"
    case medication = "Medication"
    case appointment = "Appointment"
    case labTest = "Lab Test"
    
    var icon: String {
        switch self {
        case .siteChange:
            return "bandage.fill"
        case .deviceCheck:
            return "iphone.radiowaves.left.and.right"
        case .medication:
            return "pills.fill"
        case .appointment:
            return "calendar"
        case .labTest:
            return "cross.vial.fill"
        }
    }
    
    var color: String {
        switch self {
        case .siteChange:
            return "orange"
        case .deviceCheck:
            return "blue"
        case .medication:
            return "purple"
        case .appointment:
            return "green"
        case .labTest:
            return "red"
        }
    }
}

struct Reminder: Identifiable, Codable {
    let id = UUID()
    let title: String
    let time: Date
    let type: ReminderType
    let isCompleted: Bool
    let notes: String?
    
    init(title: String, time: Date, type: ReminderType, isCompleted: Bool = false, notes: String? = nil) {
        self.title = title
        self.time = time
        self.type = type
        self.isCompleted = isCompleted
        self.notes = notes
    }
    
    var isOverdue: Bool {
        !isCompleted && time < Date()
    }
    
    var timeRemaining: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: time, relativeTo: Date())
    }
}
