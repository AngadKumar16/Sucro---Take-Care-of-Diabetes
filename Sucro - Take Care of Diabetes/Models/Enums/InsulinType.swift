//
//  InsulinType.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation

/// The kind of insulin in an `InsulinEntry`. `rawValue` is what new entries
/// store in `InsulinEntry.type`.
nonisolated enum InsulinType: String, CaseIterable, Sendable {
    case bolus = "bolus"
    case correction = "correction"
    case basal = "basal"
    case intermediate = "intermediate"
    case mixed = "mixed"
    case other = "other"

    var displayName: String {
        switch self {
        case .bolus: return "Rapid-Acting"
        case .correction: return "Correction"
        case .basal: return "Long-Acting"
        case .intermediate: return "Intermediate"
        case .mixed: return "Mixed"
        case .other: return "Other"
        }
    }

    /// Reads a stored `type` string, including the labels older builds
    /// saved ("Rapid Acting", "rapid", "Long Acting", "long", ...).
    init?(stored: String?) {
        guard let key = stored?.trimmingCharacters(in: .whitespaces).lowercased(), !key.isEmpty else {
            return nil
        }
        switch key {
        case "bolus", "rapid", "rapid acting", "rapid-acting":
            self = .bolus
        case "correction":
            self = .correction
        case "basal", "long", "long acting", "long-acting":
            self = .basal
        case "intermediate":
            self = .intermediate
        case "mixed":
            self = .mixed
        case "other":
            self = .other
        default:
            return nil
        }
    }

    /// Rapid-acting doses are the ones counted in insulin on board. Mixed
    /// insulin is left out because its rapid share isn't recorded.
    var isRapidActing: Bool {
        self == .bolus || self == .correction
    }

    /// Background insulin, reported to Apple Health as basal delivery.
    var isBasal: Bool {
        self == .basal || self == .intermediate
    }
}
