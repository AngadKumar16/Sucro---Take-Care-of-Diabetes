//
//  ReminderType.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//


//
//  ReminderType.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
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
