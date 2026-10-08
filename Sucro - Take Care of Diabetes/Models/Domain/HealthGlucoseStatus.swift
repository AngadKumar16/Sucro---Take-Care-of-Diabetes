//
//  HealthGlucoseStatus.swift
//  Sucro - Take Care of Diabetes
//
//  How fresh the glucose coming from Apple Health is, for the Devices screen.
//

import SwiftUI

enum HealthGlucoseStatus: Equatable {
    /// Nothing has been imported yet.
    case waiting
    /// The newest reading is recent enough to look like a live CGM feed.
    case receiving(age: TimeInterval)
    /// Readings have stopped arriving.
    case stale(age: TimeInterval)

    /// Same cut-off the Home screen uses to grey out an old reading.
    static let freshness: TimeInterval = 15 * 60

    init(latest: Date?, now: Date) {
        guard let latest else {
            self = .waiting
            return
        }
        let age = max(0, now.timeIntervalSince(latest))
        self = age <= Self.freshness ? .receiving(age: age) : .stale(age: age)
    }

    var title: String {
        switch self {
        case .waiting: "Waiting for Readings"
        case .receiving: "Receiving"
        case .stale: "No Recent Readings"
        }
    }

    /// How long ago the newest reading was, such as "4 min ago".
    var detail: String {
        switch self {
        case .waiting:
            ""
        case .receiving(let age), .stale(let age):
            age < 60 ? "Just now" : "\(Self.ageFormat(age)) ago"
        }
    }

    var isReceiving: Bool {
        if case .receiving = self { true } else { false }
    }

    var symbol: String {
        switch self {
        case .waiting: "hourglass"
        case .receiving: "dot.radiowaves.left.and.right"
        case .stale: "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .waiting: .secondary
        case .receiving: .green
        case .stale: .orange
        }
    }

    private static func ageFormat(_ age: TimeInterval) -> String {
        Duration.seconds(age).formatted(
            .units(allowed: [.days, .hours, .minutes], width: .abbreviated, maximumUnitCount: 1)
        )
    }
}
