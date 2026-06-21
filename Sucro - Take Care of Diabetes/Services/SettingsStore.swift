//
//  SettingsStore.swift
//  Sucro - Take Care of Diabetes
//
//  Backend store for user preferences. Persists to UserDefaults and
//  publishes changes so the UI updates live. Replaces the ephemeral
//  @State that previously backed SettingsView / DevicesView.
//

import Foundation
import Combine
import SwiftUI

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    private let defaults: UserDefaults

    // MARK: - Keys
    private enum Key {
        static let glucoseUnit = "settings.glucoseUnit"
        static let targetLow = "settings.targetLow"
        static let targetHigh = "settings.targetHigh"
        static let notificationsEnabled = "settings.notificationsEnabled"
        static let darkModeEnabled = "settings.darkModeEnabled"
        static let autoBackupEnabled = "settings.autoBackupEnabled"
        static let autoSyncEnabled = "settings.autoSyncEnabled"
        static let backgroundMonitoringEnabled = "settings.backgroundMonitoringEnabled"
        static let lowBatteryAlertsEnabled = "settings.lowBatteryAlertsEnabled"
        static let connectedDevices = "settings.connectedDevices"
    }

    // MARK: - Glucose preferences
    @Published var glucoseUnit: String {
        didSet { defaults.set(glucoseUnit, forKey: Key.glucoseUnit) }
    }
    @Published var targetLow: Double {
        didSet { defaults.set(targetLow, forKey: Key.targetLow) }
    }
    @Published var targetHigh: Double {
        didSet { defaults.set(targetHigh, forKey: Key.targetHigh) }
    }

    // MARK: - App preferences
    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Key.notificationsEnabled) }
    }
    @Published var darkModeEnabled: Bool {
        didSet { defaults.set(darkModeEnabled, forKey: Key.darkModeEnabled) }
    }
    @Published var autoBackupEnabled: Bool {
        didSet { defaults.set(autoBackupEnabled, forKey: Key.autoBackupEnabled) }
    }

    // MARK: - Device preferences
    @Published var autoSyncEnabled: Bool {
        didSet { defaults.set(autoSyncEnabled, forKey: Key.autoSyncEnabled) }
    }
    @Published var backgroundMonitoringEnabled: Bool {
        didSet { defaults.set(backgroundMonitoringEnabled, forKey: Key.backgroundMonitoringEnabled) }
    }
    @Published var lowBatteryAlertsEnabled: Bool {
        didSet { defaults.set(lowBatteryAlertsEnabled, forKey: Key.lowBatteryAlertsEnabled) }
    }

    /// Names of devices the user has connected. Persists across launches so the
    /// Devices screen's Connect/Disconnect actions have a real effect.
    @Published var connectedDeviceNames: [String] {
        didSet { defaults.set(connectedDeviceNames, forKey: Key.connectedDevices) }
    }

    // MARK: - Init
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Register sensible defaults the first time the app runs.
        defaults.register(defaults: [
            Key.glucoseUnit: "mg/dL",
            Key.targetLow: 70.0,
            Key.targetHigh: 180.0,
            Key.notificationsEnabled: true,
            Key.darkModeEnabled: false,
            Key.autoBackupEnabled: true,
            Key.autoSyncEnabled: true,
            Key.backgroundMonitoringEnabled: true,
            Key.lowBatteryAlertsEnabled: true,
            Key.connectedDevices: ["Dexcom G6", "Omnipod 5"]
        ])

        self.glucoseUnit = defaults.string(forKey: Key.glucoseUnit) ?? "mg/dL"
        self.targetLow = defaults.double(forKey: Key.targetLow)
        self.targetHigh = defaults.double(forKey: Key.targetHigh)
        self.notificationsEnabled = defaults.bool(forKey: Key.notificationsEnabled)
        self.darkModeEnabled = defaults.bool(forKey: Key.darkModeEnabled)
        self.autoBackupEnabled = defaults.bool(forKey: Key.autoBackupEnabled)
        self.autoSyncEnabled = defaults.bool(forKey: Key.autoSyncEnabled)
        self.backgroundMonitoringEnabled = defaults.bool(forKey: Key.backgroundMonitoringEnabled)
        self.lowBatteryAlertsEnabled = defaults.bool(forKey: Key.lowBatteryAlertsEnabled)
        self.connectedDeviceNames = defaults.stringArray(forKey: Key.connectedDevices) ?? []
    }

    // MARK: - Derived helpers

    /// Editable "low-high" string used by the Settings text field.
    var targetRangeString: String {
        get { "\(Int(targetLow))-\(Int(targetHigh))" }
        set {
            let parts = newValue
                .split(separator: "-")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2,
                  let low = Double(parts[0]),
                  let high = Double(parts[1]),
                  low < high else { return }
            targetLow = low
            targetHigh = high
        }
    }

    var preferredColorScheme: ColorScheme? {
        darkModeEnabled ? .dark : nil
    }

    /// Convert a stored mg/dL value into the user's preferred display unit.
    func displayGlucose(_ mgdl: Double) -> Double {
        glucoseUnit == "mmol/L" ? (mgdl / 18.0182) : mgdl
    }

    /// Formatted glucose value including the unit suffix.
    func formattedGlucose(_ mgdl: Double) -> String {
        if glucoseUnit == "mmol/L" {
            return String(format: "%.1f mmol/L", displayGlucose(mgdl))
        }
        return String(format: "%.0f mg/dL", mgdl)
    }
}
