//
//  AlertType.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//


//
//  AlertType.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import Foundation
import SwiftUI

enum AlertType {
    case lowGlucose(Double)
    case highGlucose(Double)
    case deviceOffline
    case siteChangeOverdue(Int)
    
    var title: String {
        switch self {
        case .lowGlucose:
            return "LOW GLUCOSE"
        case .highGlucose:
            return "HIGH GLUCOSE"
        case .deviceOffline:
            return "DEVICE OFFLINE"
        case .siteChangeOverdue:
            return "SITE CHANGE DUE"
        }
    }
    
    var message: String {
        switch self {
        case .lowGlucose(let value):
            return "\(Int(value)) mg/dL - Treat immediately"
        case .highGlucose(let value):
            return "\(Int(value)) mg/dL - Check for ketones"
        case .deviceOffline:
            return "CGM sensor needs replacement"
        case .siteChangeOverdue(let days):
            return "\(days) days since last change"
        }
    }
    
    var color: Color {
        switch self {
        case .lowGlucose:
            return .red
        case .highGlucose:
            return .orange
        case .deviceOffline:
            return .purple
        case .siteChangeOverdue:
            return .yellow
        }
    }
    
    var icon: String {
        switch self {
        case .lowGlucose:
            return "exclamationmark.triangle.fill"
        case .highGlucose:
            return "exclamationmark.circle.fill"
        case .deviceOffline:
            return "wifi.slash"
        case .siteChangeOverdue:
            return "bandage.fill"
        }
    }
}
