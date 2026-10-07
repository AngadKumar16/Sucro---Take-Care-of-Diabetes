//
//  LogViewModel.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import Foundation
import CoreData

@MainActor
@Observable
class LogViewModel: BaseViewModel {
    var glucoseReadings: [GlucoseReading] = []
    var carbEntries: [CarbEntry] = []
    var insulinEntries: [InsulinEntry] = []
    var activityEntries: [ActivityEntry] = []
    var selectedDate: Date = Date()
    var showAddGlucose = false
    var showAddCarbs = false
    var showAddInsulin = false
    var showAddActivity = false
    
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }
    
    func fetchEntriesForDate(_ date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        fetchGlucoseReadings(from: startOfDay, to: endOfDay)
        fetchCarbEntries(from: startOfDay, to: endOfDay)
        fetchInsulinEntries(from: startOfDay, to: endOfDay)
        fetchActivityEntries(from: startOfDay, to: endOfDay)
    }
    
    private func fetchGlucoseReadings(from start: Date, to end: Date) {
        let request: NSFetchRequest<GlucoseReading> = GlucoseReading.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReading.timestamp, ascending: false)]
        
        do {
            glucoseReadings = try viewContext.fetch(request)
        } catch {
            print("Error fetching glucose readings: \(error)")
        }
    }
    
    private func fetchCarbEntries(from start: Date, to end: Date) {
        let request: NSFetchRequest<CarbEntry> = CarbEntry.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CarbEntry.timestamp, ascending: false)]
        
        do {
            carbEntries = try viewContext.fetch(request)
        } catch {
            print("Error fetching carb entries: \(error)")
        }
    }
    
    private func fetchInsulinEntries(from start: Date, to end: Date) {
        let request: NSFetchRequest<InsulinEntry> = InsulinEntry.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \InsulinEntry.timestamp, ascending: false)]
        
        do {
            insulinEntries = try viewContext.fetch(request)
        } catch {
            print("Error fetching insulin entries: \(error)")
        }
    }
    
    private func fetchActivityEntries(from start: Date, to end: Date) {
        let request: NSFetchRequest<ActivityEntry> = ActivityEntry.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ActivityEntry.timestamp, ascending: false)]
        
        do {
            activityEntries = try viewContext.fetch(request)
        } catch {
            print("Error fetching activity entries: \(error)")
        }
    }
    
    func addGlucoseReading(value: Double, unit: String, context: String?, notes: String?) {
        let timestamp = Date()
        let reading = GlucoseReading(context: viewContext)
        reading.id = UUID()
        reading.value = value
        reading.unit = unit
        reading.timestamp = timestamp
        reading.context = context
        reading.notes = notes
        reading.trend = trendIncluding(GlucoseSample(date: timestamp, mgdl: value))?.rawValue

        save()
        HealthKitManager.shared.saveGlucoseReading(value, unit: unit, timestamp: timestamp)
        AlertService.shared.evaluate(context: viewContext)
        fetchEntriesForDate(selectedDate)
    }

    /// Trend arrow for a new reading, measured against the readings logged
    /// just before it. `nil` when there aren't any recent enough.
    private func trendIncluding(_ sample: GlucoseSample) -> GlucoseTrend? {
        let request: NSFetchRequest<GlucoseReading> = GlucoseReading.fetchRequest()
        request.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@",
            sample.date.addingTimeInterval(-GlucoseCalculator.trendWindow) as NSDate,
            sample.date as NSDate
        )
        let earlier = ((try? viewContext.fetch(request)) ?? []).compactMap(\.sample)
        return GlucoseCalculator.trend(samples: earlier + [sample])
    }

    func addCarbEntry(grams: Double, mealType: String?, foodItems: String?, notes: String?) {
        let timestamp = Date()
        let entry = CarbEntry(context: viewContext)
        entry.id = UUID()
        entry.grams = grams
        entry.mealType = mealType
        entry.foodItems = foodItems
        entry.timestamp = timestamp
        entry.notes = notes

        save()
        HealthKitManager.shared.saveCarbohydrateIntake(grams, timestamp: timestamp)
        fetchEntriesForDate(selectedDate)
    }

    func addInsulinEntry(units: Double, type: String?, deliveryMethod: String?, notes: String?) {
        let timestamp = Date()
        let entry = InsulinEntry(context: viewContext)
        entry.id = UUID()
        entry.units = units
        entry.type = type
        entry.deliveryMethod = deliveryMethod
        entry.timestamp = timestamp
        entry.notes = notes

        save()
        HealthKitManager.shared.saveInsulinDose(units, type: type ?? InsulinType.bolus.rawValue, timestamp: timestamp)
        ReminderService.shared.refresh(context: viewContext)
        fetchEntriesForDate(selectedDate)
    }

    func addActivityEntry(type: String?, duration: Int16, intensity: String?, caloriesBurned: Double, notes: String?) {
        let timestamp = Date()
        let entry = ActivityEntry(context: viewContext)
        entry.id = UUID()
        entry.type = type
        entry.duration = duration
        entry.intensity = intensity
        entry.caloriesBurned = caloriesBurned
        entry.timestamp = timestamp
        entry.notes = notes

        save()
        HealthKitManager.shared.saveWorkout(
            type ?? "Activity",
            duration: TimeInterval(duration) * 60,
            caloriesBurned: caloriesBurned,
            timestamp: timestamp
        )
        fetchEntriesForDate(selectedDate)
    }
}
