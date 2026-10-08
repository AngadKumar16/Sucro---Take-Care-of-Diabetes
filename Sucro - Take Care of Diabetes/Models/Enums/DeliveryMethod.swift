//
//  DeliveryMethod.swift
//  Sucro - Take Care of Diabetes
//

import Foundation

/// How an insulin dose was given. `rawValue` is what entries store in
/// `InsulinEntry.deliveryMethod`.
nonisolated enum DeliveryMethod: String, CaseIterable, Sendable {
    case pen = "Pen"
    case pump = "Pump"
    case syringe = "Syringe"

    /// Reads a stored value, including lowercase tags from older edit
    /// screens and "Quick Bolus", which Quick Bolus used to save.
    init?(stored: String?) {
        guard let key = stored?.trimmingCharacters(in: .whitespaces).lowercased(), !key.isEmpty else {
            return nil
        }
        switch key {
        case "pen": self = .pen
        case "pump", "quick bolus": self = .pump
        case "syringe": self = .syringe
        default: return nil
        }
    }
}
