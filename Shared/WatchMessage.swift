//
//  WatchMessage.swift
//  DiabetesCare (shared with the watch)
//
//  What the watch can ask the phone to do.
//

import Foundation

nonisolated enum WatchMessage: String, Sendable {
    /// `grams`: Double, default 15.
    case logFastSugar
    /// `grams`: Double.
    case logCarbs
    /// `mgdl`: Double.
    case logGlucose
    /// Send the latest snapshot now.
    case refresh
}
