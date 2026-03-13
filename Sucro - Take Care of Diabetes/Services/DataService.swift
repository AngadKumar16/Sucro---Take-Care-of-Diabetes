//
//  DataService.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//


//
//  DataService.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import Foundation
import CoreData

class DataService {
    static let shared = DataService()
    
    private init() {}
    
    // MARK: - Fetch Operations
    
    func fetchLatestGlucoseReading(context: NSManagedObjectContext) -> GlucoseReading? {
        let request: NSFetchRequest<GlucoseReading> = GlucoseReading.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReading.timestamp, ascending: false)]
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching latest glucose: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchRecentGlucoseReadings(context: NSManagedObjectContext, limit: Int = 10) -> [GlucoseReading] {
        let request: NSFetchRequest<GlucoseReading> = GlucoseReading.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReading.timestamp, ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching recent readings: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchTodayTotals(context: NSManagedObjectContext) -> (insulin: Double, carbs: Double) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return (0, 0)
        }
        
        var insulinTotal: Double = 0
        var carbTotal: Double = 0
        
        // Fetch insulin
        let insulinRequest: NSFetchRequest<InsulinEntry> = InsulinEntry.fetchRequest()
        insulinRequest.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let entries = try context.fetch(insulinRequest)
            insulinTotal = entries.reduce(0) { $0 + $1.units }
        } catch {
            print("Error fetching insulin totals: \(error.localizedDescription)")
        }
        
        // Fetch carbs
        let carbRequest: NSFetchRequest<CarbEntry> = CarbEntry.fetchRequest()
        carbRequest.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let entries = try context.fetch(carbRequest)
            carbTotal = entries.reduce(0) { $0 + $1.grams }
        } catch {
            print("Error fetching carb totals: \(error.localizedDescription)")
        }
        
        return (insulinTotal, carbTotal)
    }
    
    func calculateIOB(context: NSManagedObjectContext) -> Double {
        let calendar = Calendar.current
        let now = Date()
        guard let fourHoursAgo = calendar.date(byAdding: .hour, value: -4, to: now) else {
            return 0
        }
        
        let request: NSFetchRequest<InsulinEntry> = InsulinEntry.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND type == %@", fourHoursAgo as NSDate, InsulinType.bolus.rawValue)
        
        do {
            let entries = try context.fetch(request)
            return entries.reduce(0) { total, entry in
                let hoursAgo = now.timeIntervalSince(entry.timestamp ?? now) / 3600
                let remaining = entry.units * max(0, 1 - (hoursAgo / 4))
                return total + remaining
            }
        } catch {
            print("Error calculating IOB: \(error.localizedDescription)")
            return 0
        }
    }
    
    func fetchLastSiteChange(context: NSManagedObjectContext) -> SiteChange? {
        let request: NSFetchRequest<SiteChange> = SiteChange.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SiteChange.timestamp, ascending: false)]
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching last site change: \(error.localizedDescription)")
            return nil
        }
    }
    
    func getGlucoseAtTime(context: NSManagedObjectContext, time: Date) -> Double {
        let request: NSFetchRequest<GlucoseReading> = GlucoseReading.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp <= %@", time as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReading.timestamp, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let readings = try context.fetch(request)
            return readings.first?.value ?? 100.0
        } catch {
            return 100.0
        }
    }
    
    // MARK: - Delete Operations
    
    func deleteEntry<T: NSManagedObject>(context: NSManagedObjectContext, type: T.Type, at timestamp: Date) -> Bool {
        let request = T.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp == %@", timestamp as NSDate)
        request.fetchLimit = 1
        
        do {
            let entries = try context.fetch(request)
            if let entry = entries.first as? T {
                context.delete(entry)
                try context.save()
                return true
            }
        } catch {
            print("Error deleting \(T.self): \(error.localizedDescription)")
        }
        return false
    }
    
    // MARK: - Note Operations
    
    func addNoteToEntry<T: NSManagedObject>(context: NSManagedObjectContext, type: T.Type, at timestamp: Date, note: String) -> Bool {
        let request = T.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp == %@", timestamp as NSDate)
        request.fetchLimit = 1
        
        do {
            let entries = try context.fetch(request)
            if let entry = entries.first as? T {
                // Use key-value coding to set notes if property exists
                if entry.responds(to: Selector(("setNotes:"))) {
                    let existing = entry.value(forKey: "notes") as? String
                    let newNote = (existing?.isEmpty == false) ? existing! + "\n" + note : note
                    entry.setValue(newNote, forKey: "notes")
                    try context.save()
                    return true
                }
            }
        } catch {
            print("Error adding note to \(T.self): \(error.localizedDescription)")
        }
        return false
    }
    
    func fetchEntry<T: NSManagedObject>(
        context: NSManagedObjectContext,
        type: T.Type,
        at timestamp: Date
    ) -> T? {
        let request = T.fetchRequest()
        request.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp <= %@",
            timestamp.addingTimeInterval(-1) as CVarArg,
            timestamp.addingTimeInterval(1) as CVarArg
        )
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            return results.first as? T
        } catch {
            print("Error fetching entry: \(error)")
            return nil
        }
    }
}

