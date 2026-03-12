//
//  LogViewModel.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import Foundation
import CoreData
import Combine

@MainActor
class LogViewModel: BaseViewModel {
    @Published var glucoseReadings: [GlucoseReading] = []
    @Published var carbEntries: [CarbEntry] = []
    @Published var insulinEntries: [InsulinEntry] = []
    @Published var activityEntries: [ActivityEntry] = []
    @Published var selectedDate: Date = Date()
    @Published var showAddGlucose = false
    @Published var showAddCarbs = false
    @Published var showAddInsulin = false
    @Published var showAddActivity = false
    
    private var cancellables = Set<AnyCancellable>()
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
        fetchEntriesForDate(selectedDate)
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
        let reading = GlucoseReading(context: viewContext)
        reading.id = UUID()
        reading.value = value
        reading.unit = unit
        reading.timestamp = Date()
        reading.context = context
        reading.notes = notes
        
        save()
        fetchEntriesForDate(selectedDate)
    }
    
    func addCarbEntry(grams: Double, mealType: String?, foodItems: String?, notes: String?) {
        let entry = CarbEntry(context: viewContext)
        entry.id = UUID()
        entry.grams = grams
        entry.mealType = mealType
        entry.foodItems = foodItems
        entry.timestamp = Date()
        entry.notes = notes
        
        save()
        fetchEntriesForDate(selectedDate)
    }
    
    func addInsulinEntry(units: Double, type: String?, deliveryMethod: String?, notes: String?) {
        let entry = InsulinEntry(context: viewContext)
        entry.id = UUID()
        entry.units = units
        entry.type = type
        entry.deliveryMethod = deliveryMethod
        entry.timestamp = Date()
        entry.notes = notes
        
        save()
        fetchEntriesForDate(selectedDate)
    }
    
    func addActivityEntry(type: String?, duration: Int16, intensity: String?, caloriesBurned: Double, notes: String?) {
        let entry = ActivityEntry(context: viewContext)
        entry.id = UUID()
        entry.type = type
        entry.duration = duration
        entry.intensity = intensity
        entry.caloriesBurned = caloriesBurned
        entry.timestamp = Date()
        entry.notes = notes
        
        save()
        fetchEntriesForDate(selectedDate)
    }
}
