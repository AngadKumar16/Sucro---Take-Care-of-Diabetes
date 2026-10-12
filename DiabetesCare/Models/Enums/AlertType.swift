//
//  AlertType.swift
//  DiabetesCare
//
//  Created by Angad Kumar on 3/12/26.
//

import SwiftUI

/// The single most important thing to show in the Home banner. Chosen by
/// `AlertService.evaluate(context:)`.
enum AlertType: Equatable {
    case lowGlucose(Double)
    case highGlucose(Double)
    case cgmDataStale(minutes: Int)
    case siteChangeOverdue(Int)

    /// Changes whenever the banner is about a different event, so a
    /// dismissed banner comes back for the next one.
    func id(readingDate: Date?) -> String {
        let stamp = readingDate.map { String(Int($0.timeIntervalSince1970)) } ?? "none"
        switch self {
        case .lowGlucose: return "low-\(stamp)"
        case .highGlucose: return "high-\(stamp)"
        case .cgmDataStale: return "stale-\(stamp)"
        case .siteChangeOverdue(let days): return "site-\(days)"
        }
    }

    var title: String {
        switch self {
        case .lowGlucose(let value):
            return SettingsStore.shared.zone(for: value) == .urgentLow ? String(localized: "URGENT LOW") : String(localized: "LOW GLUCOSE")
        case .highGlucose:
            return String(localized: "HIGH GLUCOSE")
        case .cgmDataStale:
            return String(localized: "NO RECENT READINGS")
        case .siteChangeOverdue:
            return String(localized: "SITE CHANGE DUE")
        }
    }

    var message: String {
        let settings = SettingsStore.shared
        switch self {
        case .lowGlucose(let value):
            return String(localized: "\(settings.formattedGlucose(value)). Eat 15g of fast-acting carbs and recheck in 15 minutes.")
        case .highGlucose(let value):
            return String(localized: "\(settings.formattedGlucose(value)). Check for ketones.")
        case .cgmDataStale(let minutes):
            return String(localized: "Last reading \(Self.duration(minutes: minutes)) ago. Check your CGM sensor.")
        case .siteChangeOverdue(let days):
            return String(localized: "Last changed \(days) days ago")
        }
    }

    var color: Color {
        switch self {
        case .lowGlucose, .highGlucose: return Theme.vermilion
        case .cgmDataStale, .siteChangeOverdue: return Theme.amber
        }
    }

    var icon: String {
        switch self {
        case .lowGlucose: return "exclamationmark.triangle.fill"
        case .highGlucose: return "exclamationmark.circle.fill"
        case .cgmDataStale: return "sensor.tag.radiowaves.forward"
        case .siteChangeOverdue: return "bandage.fill"
        }
    }

    var actionTitle: String {
        switch self {
        case .lowGlucose: return String(localized: "Log Carbs")
        case .highGlucose: return String(localized: "Check Ketones")
        case .cgmDataStale: return String(localized: "Troubleshoot")
        case .siteChangeOverdue: return String(localized: "Change Site")
        }
    }

    var actionIcon: String {
        switch self {
        case .lowGlucose: return "fork.knife"
        case .highGlucose: return "drop.fill"
        case .cgmDataStale: return "wrench.and.screwdriver"
        case .siteChangeOverdue: return "arrow.triangle.2.circlepath"
        }
    }

    private static func duration(minutes: Int) -> String {
        let interval = Duration.seconds(minutes * 60)
        return interval.formatted(.units(allowed: [.hours, .minutes], width: .abbreviated, maximumUnitCount: 2))
    }
}
