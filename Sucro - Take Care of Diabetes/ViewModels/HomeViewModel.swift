//
//  HomeViewModel.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import Foundation
import CoreData
import Combine

@MainActor
class HomeViewModel: BaseViewModel {
    @Published var latestGlucoseReading: GlucoseReading?
    @Published var recentReadings: [GlucoseReading] = []
    @Published var todayInsulinTotal: Double = 0.0
    @Published var todayCarbTotal: Double = 0.0
    @Published var isConnectedDevice: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(context: NSManagedObjectContext) {
        super.init(context: context)
        fetchLatestData()
    }
    
    func fetchLatestData() {
        let glucoseRequest: NSFetchRequest<GlucoseReading> = GlucoseReading.fetchRequest()
        glucoseRequest.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReading.timestamp, ascending: false)]
        glucoseRequest.fetchLimit = 1
        
        do {
            let readings = try viewContext.fetch(glucoseRequest)
            latestGlucoseReading = readings.first
        } catch {
            print("Error fetching latest glucose: \(error)")
        }
        
        fetchRecentReadings()
        fetchTodayTotals()
    }
    
    private func fetchRecentReadings() {
        let request: NSFetchRequest<GlucoseReading> = GlucoseReading.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReading.timestamp, ascending: false)]
        request.fetchLimit = 10
        
        do {
            recentReadings = try viewContext.fetch(request)
        } catch {
            print("Error fetching recent readings: \(error)")
        }
    }
    
    private func fetchTodayTotals() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let insulinRequest: NSFetchRequest<InsulinEntry> = InsulinEntry.fetchRequest()
        insulinRequest.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let insulinEntries = try viewContext.fetch(insulinRequest)
            todayInsulinTotal = insulinEntries.reduce(0) { $0 + $1.units }
        } catch {
            print("Error fetching insulin totals: \(error)")
        }
        
        let carbRequest: NSFetchRequest<CarbEntry> = CarbEntry.fetchRequest()
        carbRequest.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let carbEntries = try viewContext.fetch(carbRequest)
            todayCarbTotal = carbEntries.reduce(0) { $0 + $1.grams }
        } catch {
            print("Error fetching carb totals: \(error)")
        }
    }
}
