//
//  HealthKitManager.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    // MARK: - Authorization
    func requestAuthorization() {
        let typesToRead: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .bloodGlucose),
            HKObjectType.quantityType(forIdentifier: .insulinDelivery),
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates),
            HKObjectType.workoutType()
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .bloodGlucose),
            HKObjectType.quantityType(forIdentifier: .insulinDelivery),
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)
        ]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if let error = error {
                    print("HealthKit authorization failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func checkAuthorizationStatus() {
        guard let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else { return }
        
        authorizationStatus = healthStore.authorizationStatus(for: glucoseType)
        isAuthorized = authorizationStatus == .sharingAuthorized
    }
    
    // MARK: - Glucose
    func saveGlucoseReading(_ value: Double, unit: String, timestamp: Date) {
        guard let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else { return }
        
        let unitString = unit == "mmol/L" ? HKUnit.moleUnit(with: .milli, with: .liter).unitDivided(by: HKUnit.moleUnit(with: .milli, with: .liter)) : HKUnit.gramUnit(with: .deci)
        let quantity = HKQuantity(unit: unitString, doubleValue: value)
        
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
        let sample = HKQuantitySample(type: insulinType, quantity: quantity, start: timestamp, end: timestamp)
        
        // Add metadata for insulin type
        var metadata = [String: Any]()
        metadata[HKMetadataKeyInsulinDeliveryReason] = HKInsulinDeliveryReason.basal.rawValue
        
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
        guard let workoutType = HKObjectType.workoutType() else { return }
        
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .other
        
        let workout = HKWorkout(
            activityType: .other,
            start: timestamp,
            end: timestamp.addingTimeInterval(duration),
            workoutEvents: nil,
            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: caloriesBurned),
            totalDistance: nil,
            metadata: nil
        )
        
        healthStore.save(workout) { success, error in
            if success {
                print("Workout saved to HealthKit")
            } else if let error = error {
                print("Failed to save workout to HealthKit: \(error.localizedDescription)")
            }
        }
    }
}
