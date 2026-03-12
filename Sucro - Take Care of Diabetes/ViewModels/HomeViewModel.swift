//
//  HomeViewModel.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import Foundation
import CoreData
import Combine
import UIKit

@MainActor
class HomeViewModel: BaseViewModel {
    @Published var latestGlucoseReading: GlucoseReading?
    @Published var recentReadings: [GlucoseReading] = []
    @Published var todayInsulinTotal: Double = 0.0
    @Published var todayCarbTotal: Double = 0.0
    @Published var insulinOnBoard: Double = 0.0
    @Published var batteryLevel: Double = 0.0
    @Published var lastSyncTime: Date?
    @Published var isConnectedDevice: Bool = false
    @Published var timelineEvents: [TimelineEvent] = []
    @Published var upcomingReminders: [Reminder] = []
    @Published var smartSuggestion: String?
    @Published var lastSiteChange: SiteChange?
    @Published var criticalAlert: AlertType?
    
    private var cancellables = Set<AnyCancellable>()
    
    override init(context: NSManagedObjectContext) {
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
        calculateIOB()
        fetchDeviceStatus()
        fetchTimelineEvents()
        fetchReminders()
        generateSmartSuggestion()
        fetchLastSiteChange()
        
        // ✅ MOVED HERE: Check for critical alerts after all data is fetched
        checkForCriticalAlerts()
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
    
    private func calculateIOB() {
        let calendar = Calendar.current
        let now = Date()
        let fourHoursAgo = calendar.date(byAdding: .hour, value: -4, to: now)!
        
        let insulinRequest: NSFetchRequest<InsulinEntry> = InsulinEntry.fetchRequest()
        insulinRequest.predicate = NSPredicate(format: "timestamp >= %@ AND type == %@", fourHoursAgo as NSDate, "bolus")
        
        do {
            let insulinEntries = try viewContext.fetch(insulinRequest)
            insulinOnBoard = insulinEntries.reduce(0) { total, entry in
                let hoursAgo = now.timeIntervalSince(entry.timestamp ?? now) / 3600
                let remaining = entry.units * max(0, 1 - (hoursAgo / 4))
                return total + remaining
            }
        } catch {
            print("Error calculating IOB: \(error)")
        }
    }
    
    private func fetchDeviceStatus() {
        batteryLevel = 0.85
        lastSyncTime = Date().addingTimeInterval(-300)
        isConnectedDevice = true
    }
    
    private func fetchTimelineEvents() {
        let calendar = Calendar.current
        let twelveHoursAgo = calendar.date(byAdding: .hour, value: -12, to: Date())!
        
        var events: [TimelineEvent] = []
        
        let carbRequest: NSFetchRequest<CarbEntry> = CarbEntry.fetchRequest()
        carbRequest.predicate = NSPredicate(format: "timestamp >= %@", twelveHoursAgo as NSDate)
        carbRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CarbEntry.timestamp, ascending: false)]
        
        do {
            let carbEntries = try viewContext.fetch(carbRequest)
            for entry in carbEntries.prefix(5) {
                let glucose = getGlucoseAtTime(entry.timestamp ?? Date())
                events.append(TimelineEvent(
                    type: .meal,
                    timestamp: entry.timestamp ?? Date(),
                    glucoseValue: glucose,
                    title: "Meal",
                    subtitle: "\(Int(entry.grams))g carbs"
                ))
            }
        } catch {
            print("Error fetching meals for timeline: \(error)")
        }
        
        let insulinRequest: NSFetchRequest<InsulinEntry> = InsulinEntry.fetchRequest()
        insulinRequest.predicate = NSPredicate(format: "timestamp >= %@ AND type == %@", twelveHoursAgo as NSDate, "bolus")
        insulinRequest.sortDescriptors = [NSSortDescriptor(keyPath: \InsulinEntry.timestamp, ascending: false)]
        
        do {
            let insulinEntries = try viewContext.fetch(insulinRequest)
            for entry in insulinEntries.prefix(5) {
                let glucose = getGlucoseAtTime(entry.timestamp ?? Date())
                events.append(TimelineEvent(
                    type: .bolus,
                    timestamp: entry.timestamp ?? Date(),
                    glucoseValue: glucose,
                    title: "Bolus",
                    subtitle: String(format: "%.1f units", entry.units)
                ))
            }
        } catch {
            print("Error fetching boluses for timeline: \(error)")
        }
        
        timelineEvents = events.sorted { $0.timestamp > $1.timestamp }
    }
    
    private func fetchReminders() {
        upcomingReminders = [
            Reminder(title: "Change infusion site", time: Date().addingTimeInterval(3600), type: .siteChange),
            Reminder(title: "Check CGM sensor", time: Date().addingTimeInterval(7200), type: .deviceCheck)
        ]
    }
    
    private func generateSmartSuggestion() {
        guard let latest = latestGlucoseReading else { return }
        
        if latest.value > 180 && latest.trend == "up" {
            smartSuggestion = "Consider checking for ketones - glucose trending up"
        } else if let lastChange = lastSiteChange {
            let daysSinceChange = Calendar.current.dateComponents([.day], from: lastChange.timestamp ?? Date(), to: Date()).day ?? 0
            if daysSinceChange >= 2 {
                smartSuggestion = "Consider changing the site - \(daysSinceChange) days since last change"
            }
        }
    }
    
    private func fetchLastSiteChange() {
        let request: NSFetchRequest<SiteChange> = SiteChange.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SiteChange.timestamp, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let siteChanges = try viewContext.fetch(request)
            lastSiteChange = siteChanges.first
        } catch {
            print("Error fetching last site change: \(error)")
        }
    }
    
    private func getGlucoseAtTime(_ time: Date) -> Double {
        let request: NSFetchRequest<GlucoseReading> = GlucoseReading.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp <= %@", time as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReading.timestamp, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let readings = try viewContext.fetch(request)
            return readings.first?.value ?? 100.0
        } catch {
            return 100.0
        }
    }
    
    // MARK: - Critical Alert Management
    func checkForCriticalAlerts() {
        criticalAlert = nil
        
        if let latest = latestGlucoseReading {
            if latest.value < 70 {
                criticalAlert = .lowGlucose(latest.value)
                return
            }
            
            if latest.value > 250 {
                criticalAlert = .highGlucose(latest.value)
                return
            }
        }
        
        if !isConnectedDevice {
            criticalAlert = .deviceOffline
            return
        }
        
        if let lastChange = lastSiteChange,
           let daysSince = Calendar.current.dateComponents([.day], from: lastChange.timestamp ?? Date(), to: Date()).day {
            if daysSince >= 3 {
                criticalAlert = .siteChangeOverdue(daysSince)
            }
        }
    }
    
    func dismissCriticalAlert() {
        criticalAlert = nil
    }
    
    func handleCriticalAlertAction() {
        guard let alert = criticalAlert else { return }
        
        switch alert {
        case .lowGlucose:
            print("Handle low glucose treatment")
        case .highGlucose:
            print("Handle high glucose ketone check")
        case .deviceOffline:
            print("Handle device offline")
        case .siteChangeOverdue:
            print("Handle site change")
        }
    }
}
