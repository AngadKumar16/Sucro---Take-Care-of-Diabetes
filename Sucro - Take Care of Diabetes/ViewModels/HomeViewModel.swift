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
    @Published var showAddCarbSheet = false
    @Published var showQuickBolusSheet = false
    @Published var showAddSiteChangeSheet = false
    @Published var selectedEvent: TimelineEvent?
    @Published var showEventDetail = false
    @Published var showNoteInput = false
    @Published var noteEventTitle: String = ""

    
    private var cancellables = Set<AnyCancellable>()
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
        fetchLatestData()
    }
    
    // MARK: - Navigation Actions
    
    func logMeal() {
        showAddCarbSheet = true
    }
        
    func quickBolus() {
        showQuickBolusSheet = true
    }
    
    func changeSite() {
        showAddSiteChangeSheet = true
    }
    
    func showEventDetails(_ event: TimelineEvent) {
        selectedEvent = event
        showEventDetail = true
    }
    
    func editEvent(_ event: TimelineEvent) {
        // Navigate to appropriate edit view based on event type
        print("Edit event: \(event.title)")
        // Implementation depends on event type
    }
    
    func deleteEvent(_ event: TimelineEvent) {
        // Fetch and delete from CoreData based on event type and timestamp
        switch event.type {
        case .meal:
            deleteCarbEntry(at: event.timestamp)
        case .bolus:
            deleteInsulinEntry(at: event.timestamp)
        case .siteChange:
            deleteSiteChange(at: event.timestamp)
        case .activity:
            deleteActivityEntry(at: event.timestamp)
        }
        
        // Refresh timeline after deletion
        fetchTimelineEvents()
    }
    
    private func deleteCarbEntry(at timestamp: Date) {
        let request: NSFetchRequest<CarbEntry> = CarbEntry.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp == %@", timestamp as NSDate)
        request.fetchLimit = 1
        
        do {
            let entries = try viewContext.fetch(request)
            if let entry = entries.first {
                viewContext.delete(entry)
                save()
            }
        } catch {
            print("Error deleting carb entry: \(error)")
        }
    }
    
    private func deleteInsulinEntry(at timestamp: Date) {
        let request: NSFetchRequest<InsulinEntry> = InsulinEntry.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp == %@", timestamp as NSDate)
        request.fetchLimit = 1
        
        do {
            let entries = try viewContext.fetch(request)
            if let entry = entries.first {
                viewContext.delete(entry)
                save()
            }
        } catch {
            print("Error deleting insulin entry: \(error)")
        }
    }
    
    private func deleteSiteChange(at timestamp: Date) {
        let request: NSFetchRequest<SiteChange> = SiteChange.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp == %@", timestamp as NSDate)
        request.fetchLimit = 1
        
        do {
            let entries = try viewContext.fetch(request)
            if let entry = entries.first {
                viewContext.delete(entry)
                save()
            }
        } catch {
            print("Error deleting site change: \(error)")
        }
    }
    
    private func deleteActivityEntry(at timestamp: Date) {
        let request: NSFetchRequest<ActivityEntry> = ActivityEntry.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp == %@", timestamp as NSDate)
        request.fetchLimit = 1
        
        do {
            let entries = try viewContext.fetch(request)
            if let entry = entries.first {
                viewContext.delete(entry)
                save()
            }
        } catch {
            print("Error deleting activity entry: \(error)")
        }
    }
    
    func showAddNote(for event: TimelineEvent) {
        noteEventTitle = event.title
        selectedEvent = event
        showNoteInput = true
    }
    
    func saveNote(_ note: String) {
        guard let event = selectedEvent else { return }
        
        // Update the appropriate CoreData entity with note based on event type
        switch event.type {
        case .meal:
            addNoteToCarbEntry(at: event.timestamp, note: note)
        case .bolus:
            addNoteToInsulinEntry(at: event.timestamp, note: note)
        case .siteChange:
            addNoteToSiteChange(at: event.timestamp, note: note)
        case .activity:
            addNoteToActivityEntry(at: event.timestamp, note: note)
        }
    }
    
    private func addNoteToCarbEntry(at timestamp: Date, note: String) {
        let request: NSFetchRequest<CarbEntry> = CarbEntry.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp == %@", timestamp as NSDate)
        request.fetchLimit = 1
        
        do {
            let entries = try viewContext.fetch(request)
            if let entry = entries.first {
                entry.notes = note
                save()
            }
        } catch {
            print("Error adding note to carb entry: \(error)")
        }
    }
    
    private func addNoteToInsulinEntry(at timestamp: Date, note: String) {
        let request: NSFetchRequest<InsulinEntry> = InsulinEntry.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp == %@", timestamp as NSDate)
        request.fetchLimit = 1
        
        do {
            let entries = try viewContext.fetch(request)
            if let entry = entries.first {
                entry.notes = note
                save()
            }
        } catch {
            print("Error adding note to insulin entry: \(error)")
        }
    }
    
    private func addNoteToSiteChange(at timestamp: Date, note: String) {
        let request: NSFetchRequest<SiteChange> = SiteChange.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp == %@", timestamp as NSDate)
        request.fetchLimit = 1
        
        do {
            let entries = try viewContext.fetch(request)
            if let entry = entries.first {
                entry.notes = note
                save()
            }
        } catch {
            print("Error adding note to site change: \(error)")
        }
    }
    
    private func addNoteToActivityEntry(at timestamp: Date, note: String) {
        let request: NSFetchRequest<ActivityEntry> = ActivityEntry.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp == %@", timestamp as NSDate)
        request.fetchLimit = 1
        
        do {
            let entries = try viewContext.fetch(request)
            if let entry = entries.first {
                entry.notes = note
                save()
            }
        } catch {
            print("Error adding note to activity entry: \(error)")
        }
    }
    
    func snoozeReminder(_ reminder: Reminder) {
        // Reschedule notification for 15 minutes later
        let newTime = Date().addingTimeInterval(15 * 60)
        NotificationService.shared.scheduleSiteChangeReminder(days: 0) { _ in
            print("Reminder snoozed to \(newTime)")
        }
    }
    
    func completeReminder(_ reminder: Reminder) {
        // Remove from upcoming reminders
        upcomingReminders.removeAll { $0.id == reminder.id }
        // Cancel any scheduled notifications for this reminder
    }
    
    // MARK: - Data Fetching
    
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
        
        // Check for critical alerts after all data is fetched
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
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        
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
        guard let fourHoursAgo = calendar.date(byAdding: .hour, value: -4, to: now) else { return }
        
        let insulinRequest: NSFetchRequest<InsulinEntry> = InsulinEntry.fetchRequest()
        insulinRequest.predicate = NSPredicate(format: "timestamp >= %@ AND type == %@", fourHoursAgo as NSDate, InsulinType.bolus.rawValue)
        
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
        guard let twelveHoursAgo = calendar.date(byAdding: .hour, value: -12, to: Date()) else { return }
        
        var events: [TimelineEvent] = []
        
        // Fetch carb entries (meals)
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
                    title: entry.mealType ?? "Meal",
                    subtitle: "\(Int(entry.grams))g carbs"
                ))
            }
        } catch {
            print("Error fetching meals for timeline: \(error)")
        }
        
        // Fetch insulin entries (boluses)
        let insulinRequest: NSFetchRequest<InsulinEntry> = InsulinEntry.fetchRequest()
        insulinRequest.predicate = NSPredicate(format: "timestamp >= %@ AND type == %@", twelveHoursAgo as NSDate, InsulinType.bolus.rawValue)
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
        
        // Fetch site changes
        let siteRequest: NSFetchRequest<SiteChange> = SiteChange.fetchRequest()
        siteRequest.predicate = NSPredicate(format: "timestamp >= %@", twelveHoursAgo as NSDate)
        siteRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SiteChange.timestamp, ascending: false)]
        
        do {
            let siteChanges = try viewContext.fetch(siteRequest)
            for entry in siteChanges.prefix(3) {
                let glucose = getGlucoseAtTime(entry.timestamp ?? Date())
                events.append(TimelineEvent(
                    type: .siteChange,
                    timestamp: entry.timestamp ?? Date(),
                    glucoseValue: glucose,
                    title: "Site Change",
                    subtitle: entry.location ?? "Unknown location"
                ))
            }
        } catch {
            print("Error fetching site changes for timeline: \(error)")
        }
        
        // Fetch activity entries
        let activityRequest: NSFetchRequest<ActivityEntry> = ActivityEntry.fetchRequest()
        activityRequest.predicate = NSPredicate(format: "timestamp >= %@", twelveHoursAgo as NSDate)
        activityRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ActivityEntry.timestamp, ascending: false)]
        
        do {
            let activityEntries = try viewContext.fetch(activityRequest)
            for entry in activityEntries.prefix(3) {
                let glucose = getGlucoseAtTime(entry.timestamp ?? Date())
                events.append(TimelineEvent(
                    type: .activity,
                    timestamp: entry.timestamp ?? Date(),
                    glucoseValue: glucose,
                    title: entry.type ?? "Activity",
                    subtitle: "\(entry.duration) min"
                ))
            }
        } catch {
            print("Error fetching activities for timeline: \(error)")
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
        
        if latest.value > 180 && latest.trend == GlucoseTrend.rising.rawValue {
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
                NotificationService.shared.scheduleCriticalGlucoseAlert(value: latest.value, isLow: true)
                return
            }
            
            if latest.value > 250 {
                criticalAlert = .highGlucose(latest.value)
                NotificationService.shared.scheduleCriticalGlucoseAlert(value: latest.value, isLow: false)
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
            // Show quick carb entry
            showAddCarbSheet = true
        case .highGlucose:
            // Navigate to ketone checking or show info
            print("Handle high glucose - check ketones")
        case .deviceOffline:
            // Navigate to device troubleshooting
            print("Handle device offline")
        case .siteChangeOverdue:
            // Show site change
            showAddSiteChangeSheet = true
        }
    }
}
