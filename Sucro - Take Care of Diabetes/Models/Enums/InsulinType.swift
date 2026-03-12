//
//  InsulinType.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation

enum InsulinType: String, CaseIterable {
    case bolus = "bolus"
    case basal = "basal"
    case correction = "correction"
    
    var displayName: String {
        switch self {
        case .bolus: return "Bolus"
        case .basal: return "Basal"
        case .correction: return "Correction"
        }
    }
}
