//
//  HealthKitManager.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation
import HealthKit

/// Writes logged data to Apple Health. Nothing in the UI observes it.
final class HealthKitManager {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    private(set) var isAuthorized = false

    /// True only on devices/simulators where HealthKit is supported.
    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization
    func requestAuthorization() async {
        guard isHealthDataAvailable else { return }
        guard let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose),
              let insulinType = HKObjectType.quantityType(forIdentifier: .insulinDelivery),
              let carbType = HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates) else {
            print("Failed to get HealthKit quantity types")
            return
        }
        
        let typesToRead: Set<HKSampleType> = [
            glucoseType,
            insulinType,
            carbType,
            HKObjectType.workoutType()
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            glucoseType,
            insulinType,
            carbType,
            HKObjectType.workoutType(),
            HKQuantityType(.activeEnergyBurned)
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            isAuthorized = true
        } catch {
            print("HealthKit authorization failed: \(error.localizedDescription)")
        }
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
                print("Glucose reading saved to HealthKit")
            } else if let error = error {
                print("Failed to save glucose to HealthKit: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchGlucoseReadings(from startDate: Date, to endDate: Date, completion: @escaping ([HKQuantitySample]) -> Void) {
        guard let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else {
            completion([])
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: glucoseType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { query, samples, error in
            if let error = error {
                print("Failed to fetch glucose from HealthKit: \(error.localizedDescription)")
                completion([])
            } else {
                completion(samples as? [HKQuantitySample] ?? [])
            }
        }
        
        healthStore.execute(query)
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
                print("Insulin dose saved to HealthKit")
            } else if let error = error {
                print("Failed to save insulin to HealthKit: \(error.localizedDescription)")
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
                print("Carbohydrate intake saved to HealthKit")
            } else if let error = error {
                print("Failed to save carbs to HealthKit: \(error.localizedDescription)")
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
                print("Failed to save workout to HealthKit: \(error.localizedDescription)")
            }
        }
    }
}
