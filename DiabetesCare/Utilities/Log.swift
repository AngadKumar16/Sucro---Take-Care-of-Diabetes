//
//  Log.swift
//  DiabetesCare
//
//  Unified logging. Failures the user can't act on go here instead of
//  `print`, so they show up in Console.app and sysdiagnoses with a category.
//

import Foundation
import OSLog

nonisolated enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "DiabetesCare"

    static let data = Logger(subsystem: subsystem, category: "data")
    static let health = Logger(subsystem: subsystem, category: "health")
    static let notifications = Logger(subsystem: subsystem, category: "notifications")
    static let backup = Logger(subsystem: subsystem, category: "backup")
    static let export = Logger(subsystem: subsystem, category: "export")
}
