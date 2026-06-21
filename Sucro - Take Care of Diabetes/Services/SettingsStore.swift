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
        static let userName = "settings.userName"
        static let diabetesType = "settings.diabetesType"
        static let glucoseUnit = "settings.glucoseUnit"
        static let targetLow = "settings.targetLow"
        static let targetHigh = "settings.targetHigh"
        static let notificationsEnabled = "settings.notificationsEnabled"
        static let darkModeEnabled = "settings.darkModeEnabled"
        static let autoBackupEnabled = "settings.autoBackupEnabled"
        static let lastBackupDate = "settings.lastBackupDate"
        static let autoSyncEnabled = "settings.autoSyncEnabled"
        static let backgroundMonitoringEnabled = "settings.backgroundMonitoringEnabled"
        static let lowBatteryAlertsEnabled = "settings.lowBatteryAlertsEnabled"
        static let connectedDevices = "settings.connectedDevices"
    }

    // MARK: - Profile
    @Published var userName: String {
        didSet { defaults.set(userName, forKey: Key.userName) }
    }
    @Published var diabetesType: String {
        didSet { defaults.set(diabetesType, forKey: Key.diabetesType) }
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
    /// Timestamp of the last automatic backup. Used to throttle backups to
    /// once per day. `nil` until the first backup runs.
    @Published var lastBackupDate: Date? {
        didSet { defaults.set(lastBackupDate, forKey: Key.lastBackupDate) }
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
            Key.userName: "Angad Kumar",
            Key.diabetesType: "Type 1 Diabetes",
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

        self.userName = defaults.string(forKey: Key.userName) ?? "Angad Kumar"
        self.diabetesType = defaults.string(forKey: Key.diabetesType) ?? "Type 1 Diabetes"
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
        self.lastBackupDate = defaults.object(forKey: Key.lastBackupDate) as? Date
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

    /// Two-letter avatar initials derived from the user's name.
    var userInitials: String {
        let initials = userName
            .split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
        let result = String(initials).uppercased()
        return result.isEmpty ? "?" : result
    }

    /// Convert a stored mg/dL value into the user's preferred display unit.
    func displayGlucose(_ mgdl: Double) -> Double {
        glucoseUnit == "mmol/L" ? (mgdl / 18.0182) : mgdl
    }

    /// Number portion of a glucose value in the user's unit (no unit suffix).
    /// mmol/L is shown with one decimal, mg/dL as a whole number.
    func glucoseValueString(_ mgdl: Double) -> String {
        glucoseUnit == "mmol/L"
            ? String(format: "%.1f", displayGlucose(mgdl))
            : String(format: "%.0f", mgdl)
    }

    /// Formatted glucose value including the unit suffix.
    func formattedGlucose(_ mgdl: Double) -> String {
        "\(glucoseValueString(mgdl)) \(glucoseUnit)"
    }

    // MARK: - Glucose thresholds (driven by the user's target range)

    /// Above this a reading is treated as urgently high (red / critical banner).
    /// Sits a fixed margin above the target ceiling so it tracks the user's range.
    var urgentHigh: Double { targetHigh + 70 }

    /// Below this a reading is treated as urgently low (red).
    var urgentLow: Double { targetLow - 20 }

    /// Whether a stored mg/dL reading falls inside the user's target range.
    func isInTargetRange(_ mgdl: Double) -> Bool {
        mgdl >= targetLow && mgdl <= targetHigh
    }

    /// Whether a reading is critical: below the target floor or urgently high.
    /// Drives the red critical banner and scheduled critical alerts.
    func isCriticalGlucose(_ mgdl: Double) -> Bool {
        mgdl < targetLow || mgdl > urgentHigh
    }
}
