//
//  HealthKitManager.swift
//  DiabetesCare
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation
import OSLog
import HealthKit

/// Writes logged data to Apple Health and owns the app's health store.
/// Reading glucose back is `HealthGlucoseImporter`'s job.
final class HealthKitManager {
    static let shared = HealthKitManager()

    let healthStore = HKHealthStore()

    private(set) var isAuthorized = false

    /// True only on devices/simulators where HealthKit is supported.
    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization
    /// Only glucose is read back (`HealthGlucoseImporter`). App Review asks
    /// for no more access than the app uses.
    private let typesToRead: Set<HKObjectType> = [
        HKQuantityType(.bloodGlucose),
    ]

    private let typesToWrite: Set<HKSampleType> = [
        HKQuantityType(.bloodGlucose),
        HKQuantityType(.insulinDelivery),
        HKQuantityType(.dietaryCarbohydrates),
        HKObjectType.workoutType(),
        HKQuantityType(.activeEnergyBurned),
    ]

    /// Shows the Health permission sheet if the user hasn't seen it for these
    /// types yet; otherwise returns straight away.
    func requestAuthorization() async {
        guard isHealthDataAvailable else { return }
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            checkAuthorizationStatus()
        } catch {
            Log.health.error("HealthKit authorization failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// True if the Health permission sheet hasn't been shown for some of the
    /// types yet. Health never says whether *reading* was allowed.
    func needsAuthorizationRequest() async -> Bool {
        guard isHealthDataAvailable else { return false }
        let status = try? await healthStore.statusForAuthorizationRequest(toShare: typesToWrite, read: typesToRead)
        return status == .shouldRequest
    }

    func checkAuthorizationStatus() {
        guard let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else { return }
        
        isAuthorized = healthStore.authorizationStatus(for: glucoseType) == .sharingAuthorized
    }
    
    // MARK: - Glucose
    func saveGlucoseReading(_ value: Double, unit: String, timestamp: Date) {
        guard let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else { return }
        
        // FIX: Proper unit handling for mg/dL vs mmol/L
        let hkUnit: HKUnit
        if unit == "mmol/L" {
            hkUnit = HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: HKUnit.liter())
        } else {
            hkUnit = HKUnit.gramUnit(with: .milli).unitDivided(by: HKUnit.literUnit(with: .deci))
        }
        
        let quantity = HKQuantity(unit: hkUnit, doubleValue: value)
        let sample = HKQuantitySample(type: glucoseType, quantity: quantity, start: timestamp, end: timestamp)
        
        healthStore.save(sample) { success, error in
            if success {
                Log.health.debug("Glucose reading saved to HealthKit")
            } else if let error = error {
                Log.health.error("Failed to save glucose to HealthKit: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    // MARK: - Insulin
    func saveInsulinDose(_ units: Double, type: String, timestamp: Date) {
        guard let insulinType = HKObjectType.quantityType(forIdentifier: .insulinDelivery) else { return }
        
        let quantity = HKQuantity(unit: HKUnit.internationalUnit(), doubleValue: units)
        
        // FIX: Proper metadata for insulin delivery reason
        var metadata: [String: Any] = [:]
        if InsulinType(stored: type)?.isBasal == true {
            metadata[HKMetadataKeyInsulinDeliveryReason] = HKInsulinDeliveryReason.basal.rawValue
        } else {
            metadata[HKMetadataKeyInsulinDeliveryReason] = HKInsulinDeliveryReason.bolus.rawValue
        }
        
        let sample = HKQuantitySample(type: insulinType, quantity: quantity, start: timestamp, end: timestamp, metadata: metadata)
        
        healthStore.save(sample) { success, error in
            if success {
                Log.health.debug("Insulin dose saved to HealthKit")
            } else if let error = error {
                Log.health.error("Failed to save insulin to HealthKit: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    // MARK: - Carbohydrates
    func saveCarbohydrateIntake(_ grams: Double, timestamp: Date) {
        guard let carbType = HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates) else { return }
        
        let quantity = HKQuantity(unit: HKUnit.gram(), doubleValue: grams)
        let sample = HKQuantitySample(type: carbType, quantity: quantity, start: timestamp, end: timestamp)
        
        healthStore.save(sample) { success, error in
            if success {
                Log.health.debug("Carbohydrate intake saved to HealthKit")
            } else if let error = error {
                Log.health.error("Failed to save carbs to HealthKit: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    // MARK: - Workout
    func saveWorkout(_ activityType: String, duration: TimeInterval, caloriesBurned: Double, timestamp: Date) {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        let end = timestamp.addingTimeInterval(duration)

        Task {
            do {
                try await builder.beginCollection(at: timestamp)
                if caloriesBurned > 0 {
                    let energy = HKQuantitySample(
                        type: HKQuantityType(.activeEnergyBurned),
                        quantity: HKQuantity(unit: .kilocalorie(), doubleValue: caloriesBurned),
                        start: timestamp,
                        end: end
                    )
                    try await builder.addSamples([energy])
                }
                try await builder.endCollection(at: end)
                _ = try await builder.finishWorkout()
            } catch {
                Log.health.error("Failed to save workout to HealthKit: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
