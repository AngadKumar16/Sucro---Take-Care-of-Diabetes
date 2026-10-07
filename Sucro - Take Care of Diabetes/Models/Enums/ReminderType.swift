//
//  ReminderType.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import SwiftUI

enum ReminderType: String, CaseIterable, Codable {
    case siteChange = "Site Change"
    case glucoseCheck = "Glucose Check"
    case deviceCheck = "Device Check"
    case medication = "Medication"

    var icon: String {
        switch self {
        case .siteChange: return "bandage.fill"
        case .glucoseCheck: return "drop.fill"
        case .deviceCheck: return "sensor.tag.radiowaves.forward.fill"
        case .medication: return "pills.fill"
        }
    }

    var tint: Color {
        switch self {
        case .siteChange: return .purple
        case .glucoseCheck: return .red
        case .deviceCheck: return .blue
        case .medication: return .green
        }
    }
}
