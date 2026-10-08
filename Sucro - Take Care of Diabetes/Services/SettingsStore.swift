//
//  SettingsStore.swift
//  Sucro - Take Care of Diabetes
//
//  Backend store for user preferences. Persists to UserDefaults and
//  publishes changes so the UI updates live. Replaces the ephemeral
//  @State that previously backed SettingsView / DevicesView.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class SettingsStore {
    static let shared = SettingsStore()

    @ObservationIgnored private let defaults: UserDefaults

    // MARK: - Keys
    private enum Key {
        static let userName = "settings.userName"
        static let diabetesType = "settings.diabetesType"
        static let glucoseUnit = "settings.glucoseUnit"
        static let targetLow = "settings.targetLow"
        static let targetHigh = "settings.targetHigh"
        static let urgentLow = "settings.urgentLow"
        static let urgentHigh = "settings.urgentHigh"
        static let insulinActionHours = "settings.insulinActionHours"
        static let acceptedDisclaimerVersion = "settings.acceptedDisclaimerVersion"
        static let notificationsEnabled = "settings.notificationsEnabled"
        /// Pre-2026-10 builds stored a dark mode on/off switch here.
        static let legacyDarkModeEnabled = "settings.darkModeEnabled"
        static let appearance = "settings.appearance"
        static let lastDeliveryMethod = "settings.lastDeliveryMethod"
        static let savedGlossaryTerms = "settings.savedGlossaryTerms"
        static let autoBackupEnabled = "settings.autoBackupEnabled"
        static let lastBackupDate = "settings.lastBackupDate"
    }

    // MARK: - Profile
    var userName: String {
        didSet { defaults.set(userName, forKey: Key.userName) }
    }
    var diabetesType: String {
        didSet { defaults.set(diabetesType, forKey: Key.diabetesType) }
    }

    // MARK: - Glucose preferences
    var glucoseUnit: String {
        didSet { defaults.set(glucoseUnit, forKey: Key.glucoseUnit) }
    }
    var targetLow: Double {
        didSet { defaults.set(targetLow, forKey: Key.targetLow) }
    }
    var targetHigh: Double {
        didSet { defaults.set(targetHigh, forKey: Key.targetHigh) }
    }
    /// Readings below this are an urgent low. Always below `targetLow`.
    var urgentLow: Double {
        didSet { defaults.set(urgentLow, forKey: Key.urgentLow) }
    }
    /// Readings above this are an urgent high. Always above `targetHigh`.
    var urgentHigh: Double {
        didSet { defaults.set(urgentHigh, forKey: Key.urgentHigh) }
    }

    // MARK: - Insulin
    /// Duration of insulin action (DIA) in hours for rapid-acting insulin.
    /// Drives the insulin-on-board estimate.
    var insulinActionHours: Double {
        didSet { defaults.set(insulinActionHours, forKey: Key.insulinActionHours) }
    }

    // MARK: - Disclaimer
    /// Version of the medical disclaimer the user last accepted. Bump
    /// `currentDisclaimerVersion` when the wording changes materially.
    var acceptedDisclaimerVersion: Int {
        didSet { defaults.set(acceptedDisclaimerVersion, forKey: Key.acceptedDisclaimerVersion) }
    }
    static let currentDisclaimerVersion = 1

    var hasAcceptedDisclaimer: Bool {
        acceptedDisclaimerVersion >= Self.currentDisclaimerVersion
    }

    // MARK: - App preferences
    var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Key.notificationsEnabled) }
    }
    /// Light/dark override. `.system` (the default) follows the phone.
    var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) }
    }
    var autoBackupEnabled: Bool {
        didSet { defaults.set(autoBackupEnabled, forKey: Key.autoBackupEnabled) }
    }
    /// Timestamp of the last automatic backup. Used to throttle backups to
    /// once per day. `nil` until the first backup runs.
    var lastBackupDate: Date? {
        didSet { defaults.set(lastBackupDate, forKey: Key.lastBackupDate) }
    }

    // MARK: - Logging defaults
    /// How the last insulin dose was delivered, so the Add Insulin form
    /// starts on the method the user actually uses.
    var lastDeliveryMethod: DeliveryMethod {
        didSet { defaults.set(lastDeliveryMethod.rawValue, forKey: Key.lastDeliveryMethod) }
    }

    // MARK: - Glossary
    /// Ids of glossary terms the user saved, most recent first.
    var savedGlossaryTermIDs: [String] {
        didSet { defaults.set(savedGlossaryTermIDs, forKey: Key.savedGlossaryTerms) }
    }

    func isSaved(_ term: GlossaryTerm) -> Bool {
        savedGlossaryTermIDs.contains(term.id)
    }

    func toggleSaved(_ term: GlossaryTerm) {
        if let index = savedGlossaryTermIDs.firstIndex(of: term.id) {
            savedGlossaryTermIDs.remove(at: index)
        } else {
            savedGlossaryTermIDs.insert(term.id, at: 0)
        }
    }

    // MARK: - Init
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Register sensible defaults the first time the app runs.
        defaults.register(defaults: [
            Key.userName: "",
            Key.diabetesType: "Type 1 Diabetes",
            Key.glucoseUnit: "mg/dL",
            Key.targetLow: 70.0,
            Key.targetHigh: 180.0,
            Key.urgentLow: 55.0,
            Key.urgentHigh: 250.0,
            Key.insulinActionHours: 4.0,
            Key.acceptedDisclaimerVersion: 0,
            Key.notificationsEnabled: true,
            Key.autoBackupEnabled: true
        ])

        self.userName = defaults.string(forKey: Key.userName) ?? ""
        self.diabetesType = defaults.string(forKey: Key.diabetesType) ?? "Type 1 Diabetes"
        self.glucoseUnit = defaults.string(forKey: Key.glucoseUnit) ?? "mg/dL"
        self.targetLow = defaults.double(forKey: Key.targetLow)
        self.targetHigh = defaults.double(forKey: Key.targetHigh)
        self.urgentLow = defaults.double(forKey: Key.urgentLow)
        self.urgentHigh = defaults.double(forKey: Key.urgentHigh)
        self.insulinActionHours = defaults.double(forKey: Key.insulinActionHours)
        self.acceptedDisclaimerVersion = defaults.integer(forKey: Key.acceptedDisclaimerVersion)
        self.notificationsEnabled = defaults.bool(forKey: Key.notificationsEnabled)
        self.appearance = Self.loadAppearance(from: defaults)
        self.autoBackupEnabled = defaults.bool(forKey: Key.autoBackupEnabled)
        self.savedGlossaryTermIDs = defaults.stringArray(forKey: Key.savedGlossaryTerms) ?? []
        self.lastDeliveryMethod = DeliveryMethod(stored: defaults.string(forKey: Key.lastDeliveryMethod)) ?? .pen
        self.lastBackupDate = defaults.object(forKey: Key.lastBackupDate) as? Date

        normalizeThresholds()
        insulinActionHours = min(max(insulinActionHours, Self.insulinActionBounds.lowerBound), Self.insulinActionBounds.upperBound)
    }

    /// Older builds only stored a target range, and allowed any low < high.
    /// Nudge the urgent lines so the four thresholds are strictly ordered.
    private func normalizeThresholds() {
        let step = Self.thresholdStep
        if targetHigh - targetLow < 2 * step { targetHigh = targetLow + 2 * step }
        if urgentLow >= targetLow { urgentLow = max(40, targetLow - step) }
        if urgentLow >= targetLow { targetLow = urgentLow + step }
        if urgentHigh <= targetHigh { urgentHigh = targetHigh + step }
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
                  low < high,
                  low > urgentLow,
                  high < urgentHigh else { return }
            targetLow = low
            targetHigh = high
        }
    }

    var preferredColorScheme: ColorScheme? {
        appearance.colorScheme
    }

    /// Reads the appearance, carrying over the old dark mode switch: on
    /// meant dark, off meant follow the system.
    private static func loadAppearance(from defaults: UserDefaults) -> Appearance {
        if let stored = defaults.string(forKey: Key.appearance), let appearance = Appearance(rawValue: stored) {
            return appearance
        }
        return defaults.bool(forKey: Key.legacyDarkModeEnabled) ? .dark : .system
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
            ? displayGlucose(mgdl).formatted(.number.precision(.fractionLength(1)))
            : mgdl.formatted(.number.precision(.fractionLength(0)))
    }

    /// Convert a value typed in the user's display unit back to mg/dL for storage.
    func mgdl(fromDisplay value: Double) -> Double {
        glucoseUnit == "mmol/L" ? value * 18.0182 : value
    }

    /// Glucose values outside this range (mg/dL) are almost certainly typos.
    static let plausibleGlucose: ClosedRange<Double> = 20...600

    /// Formatted glucose value including the unit suffix.
    func formattedGlucose(_ mgdl: Double) -> String {
        "\(glucoseValueString(mgdl)) \(glucoseUnit)"
    }

    // MARK: - Glucose thresholds

    /// The four user thresholds as one value. Every color, banner and alert
    /// classifies readings through this, so they can't disagree.
    var thresholds: GlucoseThresholds {
        GlucoseThresholds(
            urgentLow: urgentLow,
            targetLow: targetLow,
            targetHigh: targetHigh,
            urgentHigh: urgentHigh
        )
    }

    func zone(for mgdl: Double) -> GlucoseZone {
        thresholds.zone(for: mgdl)
    }

    /// Whether a stored mg/dL reading falls inside the user's target range.
    func isInTargetRange(_ mgdl: Double) -> Bool {
        zone(for: mgdl) == .inRange
    }

    /// Whether a reading needs action now: any low, or an urgent high.
    func isCriticalGlucose(_ mgdl: Double) -> Bool {
        zone(for: mgdl).needsAction
    }

    // Allowed ranges for each threshold in mg/dL, keeping them strictly
    // ordered: urgentLow < targetLow < targetHigh < urgentHigh.
    static let thresholdStep: Double = 5
    var urgentLowBounds: ClosedRange<Double> { Self.range(40, targetLow - Self.thresholdStep) }
    var targetLowBounds: ClosedRange<Double> { Self.range(urgentLow + Self.thresholdStep, targetHigh - 2 * Self.thresholdStep) }
    var targetHighBounds: ClosedRange<Double> { Self.range(targetLow + 2 * Self.thresholdStep, urgentHigh - Self.thresholdStep) }
    var urgentHighBounds: ClosedRange<Double> { Self.range(targetHigh + Self.thresholdStep, 400) }

    /// A range that never traps, even if the bounds cross.
    private static func range(_ lower: Double, _ upper: Double) -> ClosedRange<Double> {
        lower...max(lower, upper)
    }

    static let insulinActionBounds: ClosedRange<Double> = 3...6
}
