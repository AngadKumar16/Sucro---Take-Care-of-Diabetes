//
//  Glance.swift
//  DiabetesCare (shared with the widgets and the watch)
//
//  A small snapshot of "how am I doing right now" that the app writes to
//  the shared App Group container after every change, and widgets, Live
//  Activities and the watch read. Glucose is in mg/dL, like everywhere.
//

import Foundation
import SwiftUI

nonisolated enum AppGroup {
    /// The watch keeps its own group: it can't share a container with the
    /// phone, so the snapshot reaches it over WatchConnectivity instead.
    #if os(watchOS)
    static let id = "group.com.AngadKumar16.DiabetesCare.watch"
    #else
    static let id = "group.com.AngadKumar16.DiabetesCare"
    #endif

    static var defaults: UserDefaults { UserDefaults(suiteName: id) ?? .standard }
}

nonisolated struct GlanceSnapshot: Codable, Equatable, Sendable {
    struct Point: Codable, Equatable, Sendable {
        var date: Date
        var mgdl: Double
    }

    var updatedAt: Date
    var latest: Point?
    /// `GlucoseTrend` raw value of the latest reading.
    var trend: String?
    /// Readings from the last 3 hours, oldest first.
    var recent: [Point] = []
    var insulinOnBoard: Double = 0
    var carbsToday: Double = 0
    var unit: String = "mg/dL"
    var urgentLow: Double = 55
    var targetLow: Double = 70
    var targetHigh: Double = 180
    var urgentHigh: Double = 250
    /// `CareStage` raw value.
    var stage: String = "adult"
    var name: String = ""
    var loggingStreak: Int = 0
    /// While a low is being treated: when to check again.
    var lowRecheckAt: Date?

    static let placeholder = GlanceSnapshot(
        updatedAt: .now,
        latest: Point(date: .now.addingTimeInterval(-180), mgdl: 112),
        trend: "stable",
        recent: (0..<36).map { Point(date: .now.addingTimeInterval(Double(-36 + $0) * 300), mgdl: 120 + 30 * sin(Double($0) / 6)) },
        insulinOnBoard: 1.2,
        carbsToday: 85,
        loggingStreak: 5
    )

    // MARK: - Store

    private static let key = "glance.snapshot"

    static func load(from defaults: UserDefaults = AppGroup.defaults) -> GlanceSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(GlanceSnapshot.self, from: data)
    }

    func save(to defaults: UserDefaults = AppGroup.defaults) {
        if let data = try? JSONEncoder().encode(self) { defaults.set(data, forKey: Self.key) }
    }

    // MARK: - Reading it

    /// A reading older than this may not reflect glucose now.
    static let staleAfter: TimeInterval = 15 * 60

    func isStale(at date: Date) -> Bool {
        guard let latest else { return true }
        return date.timeIntervalSince(latest.date) > Self.staleAfter
    }

    var isMmol: Bool { unit == "mmol/L" }

    func value(_ mgdl: Double) -> String {
        isMmol
            ? (mgdl / 18.0182).formatted(.number.precision(.fractionLength(1)))
            : mgdl.formatted(.number.precision(.fractionLength(0)))
    }

    func display(_ mgdl: Double) -> Double { isMmol ? mgdl / 18.0182 : mgdl }

    enum Zone: Sendable { case urgentLow, low, inRange, high, urgentHigh }

    func zone(_ mgdl: Double) -> Zone {
        if mgdl < urgentLow { return .urgentLow }
        if mgdl < targetLow { return .low }
        if mgdl <= targetHigh { return .inRange }
        if mgdl <= urgentHigh { return .high }
        return .urgentHigh
    }

    var trendSymbol: String? {
        switch trend {
        case "rising_fast": "arrow.up.to.line"
        case "rising": "arrow.up.right"
        case "stable": "arrow.right"
        case "falling": "arrow.down.right"
        case "falling_fast": "arrow.down.to.line"
        default: nil
        }
    }
}

extension GlanceSnapshot.Zone {
    /// Same inks as the app: green in range, amber high, vermilion low.
    var color: Color {
        switch self {
        case .inRange: Color(red: 0.20, green: 0.62, blue: 0.40)
        case .high: Color(red: 0.86, green: 0.55, blue: 0.20)
        case .low, .urgentLow, .urgentHigh: Color(red: 0.90, green: 0.33, blue: 0.22)
        }
    }

    var name: String {
        switch self {
        case .urgentLow: String(localized: "Urgent low")
        case .low: String(localized: "Low")
        case .inRange: String(localized: "In range")
        case .high: String(localized: "High")
        case .urgentHigh: String(localized: "Urgent high")
        }
    }
}
