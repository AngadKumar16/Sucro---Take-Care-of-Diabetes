//
//  TimelineService.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//


//
//  TimelineService.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import Foundation
import CoreData

class TimelineService {
    static let shared = TimelineService()
    
    private init() {}
    
    /// Events from the last `hoursBack` hours, newest first. With `limited`,
    /// only the latest few of each kind, for short summaries.
    func buildTimeline(context: NSManagedObjectContext, hoursBack: Int = 12, limited: Bool = true) -> [TimelineEvent] {
        let calendar = Calendar.current
        guard let startTime = calendar.date(byAdding: .hour, value: -hoursBack, to: Date()) else {
            return []
        }
        
        var events: [TimelineEvent] = []
        let dataService = DataService.shared
        
        // Fetch meals
        events += fetchMeals(context: context, since: startTime, limit: limited ? 5 : nil, dataService: dataService)
        
        // Fetch boluses
        events += fetchBoluses(context: context, since: startTime, limit: limited ? 5 : nil, dataService: dataService)
        
        // Fetch site changes
        events += fetchSiteChanges(context: context, since: startTime, limit: limited ? 3 : nil, dataService: dataService)
        
        // Fetch activities
        events += fetchActivities(context: context, since: startTime, limit: limited ? 3 : nil, dataService: dataService)
        
        return events.sorted { $0.timestamp > $1.timestamp }
    }
    
    private func fetchMeals(context: NSManagedObjectContext, since: Date, limit: Int?, dataService: DataService) -> [TimelineEvent] {
        let request: NSFetchRequest<CarbEntry> = CarbEntry.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@", since as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CarbEntry.timestamp, ascending: false)]
        
        do {
            let entries = try context.fetch(request)
            return entries.prefix(limit ?? .max).map { entry in
                let glucose = dataService.getGlucoseAtTime(context: context, time: entry.timestamp ?? Date())
                return TimelineEvent(
                    type: .meal,
                    timestamp: entry.timestamp ?? Date(),
                    glucoseValue: glucose,
                    title: MealType(stored: entry.mealType)?.rawValue ?? entry.mealType ?? "Meal",
                    subtitle: "\(entry.grams.formatted(.number.precision(.fractionLength(0...1))))g carbs",
                    notes: entry.notes,
                    objectID: entry.objectID
                )
            }
        } catch {
            print("Error fetching meals: \(error.localizedDescription)")
            return []
        }
    }
    
    private func fetchBoluses(context: NSManagedObjectContext, since: Date, limit: Int?, dataService: DataService) -> [TimelineEvent] {
        let request: NSFetchRequest<InsulinEntry> = InsulinEntry.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@", since as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \InsulinEntry.timestamp, ascending: false)]
        
        do {
            let entries = try context.fetch(request)
                .filter { InsulinType(stored: $0.type)?.isRapidActing == true }
            return entries.prefix(limit ?? .max).map { entry in
                let glucose = dataService.getGlucoseAtTime(context: context, time: entry.timestamp ?? Date())
                return TimelineEvent(
                    type: .bolus,
                    timestamp: entry.timestamp ?? Date(),
                    glucoseValue: glucose,
                    title: "Bolus",
                    subtitle: "\(entry.units.formatted(.number.precision(.fractionLength(0...1)))) units",
                    notes: entry.notes,
                    objectID: entry.objectID
                )
            }
        } catch {
            print("Error fetching boluses: \(error.localizedDescription)")
            return []
        }
    }
    
    private func fetchSiteChanges(context: NSManagedObjectContext, since: Date, limit: Int?, dataService: DataService) -> [TimelineEvent] {
        let request: NSFetchRequest<SiteChange> = SiteChange.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@", since as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SiteChange.timestamp, ascending: false)]
        
        do {
            let entries = try context.fetch(request)
            return entries.prefix(limit ?? .max).map { entry in
                let glucose = dataService.getGlucoseAtTime(context: context, time: entry.timestamp ?? Date())
                return TimelineEvent(
                    type: .siteChange,
                    timestamp: entry.timestamp ?? Date(),
                    glucoseValue: glucose,
                    title: "Site Change",
                    subtitle: entry.location ?? "Unknown location",
                    notes: entry.notes,
                    objectID: entry.objectID
                )
            }
        } catch {
            print("Error fetching site changes: \(error.localizedDescription)")
            return []
        }
    }
    
    private func fetchActivities(context: NSManagedObjectContext, since: Date, limit: Int?, dataService: DataService) -> [TimelineEvent] {
        let request: NSFetchRequest<ActivityEntry> = ActivityEntry.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@", since as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ActivityEntry.timestamp, ascending: false)]
        
        do {
            let entries = try context.fetch(request)
            return entries.prefix(limit ?? .max).map { entry in
                let glucose = dataService.getGlucoseAtTime(context: context, time: entry.timestamp ?? Date())
                return TimelineEvent(
                    type: .activity,
                    timestamp: entry.timestamp ?? Date(),
                    glucoseValue: glucose,
                    title: entry.type ?? "Activity",
                    subtitle: "\(entry.duration) min",
                    notes: entry.notes,
                    objectID: entry.objectID
                )
            }
        } catch {
            print("Error fetching activities: \(error.localizedDescription)")
            return []
        }
    }
}