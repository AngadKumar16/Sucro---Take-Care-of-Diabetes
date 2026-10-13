//
//  KetoneReading.swift
//  DiabetesCare
//
//  A ketone check, from a blood meter (mmol/L) or a urine strip (a color
//  level). Logged for the record and the sick-day checklist; the levels
//  describe what's common guidance, never a treatment.
//

import CoreData
import Foundation

@objc(KetoneReading)
public class KetoneReading: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    /// Blood: mmol/L. Urine: the strip level's raw value (`UrineKetones`).
    @NSManaged public var value: Double
    @NSManaged public var method: String?
    @NSManaged public var notes: String?
}

extension KetoneReading {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<KetoneReading> {
        NSFetchRequest<KetoneReading>(entityName: "KetoneReading")
    }

    var ketoneMethod: KetoneMethod { KetoneMethod(rawValue: method ?? "") ?? .blood }

    var level: KetoneZone { KetoneZone(value: value, method: ketoneMethod) }

    var displayValue: String { KetoneZone.display(value: value, method: ketoneMethod) }
}

extension KetoneReading: Identifiable {}

nonisolated enum KetoneMethod: String, CaseIterable, Sendable {
    case blood
    case urine

    var name: String {
        switch self {
        case .blood: String(localized: "Blood")
        case .urine: String(localized: "Urine strip")
        }
    }
}

/// Urine strip colors, stored by their raw value.
nonisolated enum UrineKetones: Int, CaseIterable, Sendable {
    case negative, trace, small, moderate, large

    var name: String {
        switch self {
        case .negative: String(localized: "Negative")
        case .trace: String(localized: "Trace")
        case .small: String(localized: "Small")
        case .moderate: String(localized: "Moderate")
        case .large: String(localized: "Large")
        }
    }
}

nonisolated enum KetoneZone: Int, Comparable, Sendable {
    case normal, raised, high, veryHigh

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Common thresholds: blood under 0.6 mmol/L is normal, 0.6–1.5 raised,
    /// 1.6–3.0 high, over 3.0 very high. Urine: trace/small, moderate, large.
    init(value: Double, method: KetoneMethod) {
        switch method {
        case .blood:
            self = value < 0.6 ? .normal : value <= 1.5 ? .raised : value <= 3.0 ? .high : .veryHigh
        case .urine:
            switch UrineKetones(rawValue: Int(value.rounded())) ?? .negative {
            case .negative: self = .normal
            case .trace, .small: self = .raised
            case .moderate: self = .high
            case .large: self = .veryHigh
            }
        }
    }

    var name: String {
        switch self {
        case .normal: String(localized: "Normal")
        case .raised: String(localized: "Raised")
        case .high: String(localized: "High")
        case .veryHigh: String(localized: "Very high")
        }
    }

    /// What common sick-day plans say, phrased as information.
    var guidance: String {
        switch self {
        case .normal: String(localized: "Keep checking as your plan says.")
        case .raised: String(localized: "Drink water and check again in 1–2 hours.")
        case .high: String(localized: "Call your care team now, as your sick-day plan says.")
        case .veryHigh: String(localized: "Get help now. Call your care team or emergency services.")
        }
    }

    static func display(value: Double, method: KetoneMethod) -> String {
        switch method {
        case .blood: "\(value.formatted(.number.precision(.fractionLength(1)))) mmol/L"
        case .urine: (UrineKetones(rawValue: Int(value.rounded())) ?? .negative).name
        }
    }
}
