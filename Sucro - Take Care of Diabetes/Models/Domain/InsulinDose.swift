//
//  InsulinDose.swift
//  Sucro - Take Care of Diabetes
//

import Foundation

/// A single insulin dose.
nonisolated struct InsulinDose: Equatable, Sendable {
    let date: Date
    let units: Double
    let type: InsulinType?
}

extension InsulinEntry {
    var dose: InsulinDose? {
        guard let timestamp else { return nil }
        return InsulinDose(date: timestamp, units: units, type: InsulinType(stored: type))
    }
}
