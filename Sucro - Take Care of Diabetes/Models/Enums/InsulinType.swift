//
//  InsulinType.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//



import Foundation

enum InsulinType: String, CaseIterable, Codable {
    case bolus = "bolus"
    case basal = "basal"
    
    var description: String {
        switch self {
        case .bolus:
            return "Bolus (Meal)"
        case .basal:
            return "Basal (Background)"
        }
    }
}
