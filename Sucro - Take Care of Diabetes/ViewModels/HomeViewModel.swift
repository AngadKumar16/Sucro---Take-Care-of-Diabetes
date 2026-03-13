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
    // MARK: - Published Properties
    @Published var latestGlucoseReading: GlucoseReading?
    @Published var recentReadings: [GlucoseReading] = []
    @Published var todayInsulinTotal: Double = 0.0
    @Published var todayCarbTotal: Double = 0.0
    @Published var insulinOnBoard: Double = 0.0
    
    // REMOVED: Hardcoded fake values
    // @Published var batteryLevel: Double = 0.85
    // @Published var lastSyncTime: Date? = Date().addingTimeInterval(-300)
    // @Published var isConnectedDevice: Bool = true
    
    @Published var timelineEvents: [TimelineEvent] = []
    @Published var upcomingReminders: [Reminder] = []
    @Published var smartSuggestion: String?
    @Published var lastSiteChange: SiteChange?
    @Published var criticalAlert: AlertType?
    
    // MARK: - Navigation State
    @Published var showAddCarbSheet = false
    @Published var showQuickBolusSheet = false
    @Published var showAddSiteChangeSheet = false
    @Published var selectedEvent: TimelineEvent?
    @Published var showEventDetail = false
    @Published var showNoteInput = false
    @Published var noteEventTitle: String = ""
    
    // REMOVED: @Published var showEditSheet = false (replaced with editOperation)
    
    // MARK: - New Published Properties for Real Implementations
    var editOperation: DraftOperation<NSManagedObject>?
    @Published var showKetoneInfoSheet = false
    @Published var showTroubleshootingSheet = false
    
    // MARK: - Services
    private let dataService = DataService.shared
    private let timelineService = TimelineService.shared
    private let alertService = AlertService.shared
    
    // REPLACED: private let reminderService = ReminderService.shared
    private let reminderService = RealReminderService.shared
    
    // ADDED: Real device monitoring
    private let deviceMonitor = DeviceMonitorService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties for Device Status (REPLACED HARDCODED VALUES)
    var batteryLevel: Double {
        deviceMonitor.batteryLevel
    }
    
    var batteryState: UIDevice.BatteryState {
        deviceMonitor.batteryState
    }
    
    var isConnectedDevice: Bool {
        deviceMonitor.isConnected
    }
    
    var lastSyncTime: Date? {
        deviceMonitor.lastSyncTime
    }
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
        
        // Bind device monitor updates to refresh UI
        deviceMonitor.$lastSyncTime
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        deviceMonitor.$batteryLevel
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
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
    
    // MARK: - Real Edit Function (REPLACED PLACEHOLDER)
    func editEvent(_ event: TimelineEvent) {
        selectedEvent = event
        showEventDetail = false
        
        switch event.type {
        case .meal:
            guard let carbEntry = dataService.fetchEntry(
                context: viewContext,
                type: CarbEntry.self,
                at: event.timestamp
            ) else { return }
            
            editOperation = DraftOperation(
                withExistingObject: carbEntry,
                inParentContext: viewContext,
                onSave: { [weak self] in
                    self?.fetchTimelineEvents()
                }
            )
            
        case .bolus:
            guard let insulinEntry = dataService.fetchEntry(
                context: viewContext,
                type: InsulinEntry.self,
                at: event.timestamp
            ) else { return }
            
            editOperation = DraftOperation(
                withExistingObject: insulinEntry,
                inParentContext: viewContext,
                onSave: { [weak self] in
                    self?.fetchTimelineEvents()
                }
            )
            
        case .siteChange:
            guard let siteChange = dataService.fetchEntry(
                context: viewContext,
                type: SiteChange.self,
                at: event.timestamp
            ) else { return }
            
            editOperation = DraftOperation(
                withExistingObject: siteChange,
                inParentContext: viewContext,
                onSave: { [weak self] in
                    self?.fetchTimelineEvents()
                }
            )
            
        case .activity:
            // Handle activity editing if needed
            break
        }
    }
    
    func deleteEvent(_ event: TimelineEvent) {
        let success: Bool
        switch event.type {
        case .meal:
            success = dataService.deleteEntry(context: viewContext, type: CarbEntry.self, at: event.timestamp)
        case .bolus:
            success = dataService.deleteEntry(context: viewContext, type: InsulinEntry.self, at: event.timestamp)
        case .siteChange:
            success = dataService.deleteEntry(context: viewContext, type: SiteChange.self, at: event.timestamp)
        case .activity:
            success = dataService.deleteEntry(context: viewContext, type: ActivityEntry.self, at: event.timestamp)
        }
        
        if success {
            selectedEvent = nil
            showEventDetail = false
            fetchTimelineEvents()
        }
    }
    
    func showAddNote(for event: TimelineEvent) {
        noteEventTitle = event.title
        selectedEvent = event
        showNoteInput = true
    }
    
    func saveNote(_ note: String) {
        guard let event = selectedEvent else { return }
        
        let success: Bool
        switch event.type {
        case .meal:
            success = dataService.addNoteToEntry(context: viewContext, type: CarbEntry.self, at: event.timestamp, note: note)
        case .bolus:
            success = dataService.addNoteToEntry(context: viewContext, type: InsulinEntry.self, at: event.timestamp, note: note)
        case .siteChange:
            success = dataService.addNoteToEntry(context: viewContext, type: SiteChange.self, at: event.timestamp, note: note)
        case .activity:
            success = dataService.addNoteToEntry(context: viewContext, type: ActivityEntry.self, at: event.timestamp, note: note)
        }
        
        if success {
            showNoteInput = false
            fetchTimelineEvents()
        }
    }
    
    // MARK: - Real Reminder Actions (REPLACED MOCK)
    func snoozeReminder(_ reminder: Reminder) {
        reminderService.snoozeReminder(reminder, minutes: 15)
        // Refresh reminders list
        upcomingReminders = reminderService.upcomingReminders
    }
    
    func completeReminder(_ reminder: Reminder) {
        reminderService.completeReminder(reminder)
        // Refresh reminders list
        upcomingReminders = reminderService.upcomingReminders
    }
    
    // MARK: - Data Fetching
    
    func fetchLatestData() {
        latestGlucoseReading = dataService.fetchLatestGlucoseReading(context: viewContext)
        recentReadings = dataService.fetchRecentGlucoseReadings(context: viewContext, limit: 10)
        
        let totals = dataService.fetchTodayTotals(context: viewContext)
        todayInsulinTotal = totals.insulin
        todayCarbTotal = totals.carbs
        
        insulinOnBoard = dataService.calculateIOB(context: viewContext)
        lastSiteChange = dataService.fetchLastSiteChange(context: viewContext)
        
        fetchTimelineEvents()
        fetchReminders()
        generateSmartSuggestion()
        checkForCriticalAlerts()
        
        // Update device monitor with latest sync
        if latestGlucoseReading != nil {
            deviceMonitor.recordSync()
        }
    }
    
    private func fetchTimelineEvents() {
        timelineEvents = timelineService.buildTimeline(context: viewContext, hoursBack: 12)
    }
    
    // MARK: - Real Reminders (REPLACED MOCK)
    private func fetchReminders() {
        reminderService.scheduleReminders(
            for: lastSiteChange,
            insulinOnBoard: insulinOnBoard,
            context: viewContext
        )
        upcomingReminders = reminderService.upcomingReminders
    }
    
    private func generateSmartSuggestion() {
        guard let latest = latestGlucoseReading else { return }
        
        if latest.value > 180 && latest.trend == GlucoseTrend.rising.rawValue {
            smartSuggestion = "Consider checking for ketones - glucose trending up"
        } else if let lastChange = lastSiteChange {
            let daysSince = Calendar.current.dateComponents([.day], from: lastChange.timestamp ?? Date(), to: Date()).day ?? 0
            if daysSince >= 2 {
                smartSuggestion = "Consider changing the site - \(daysSince) days since last change"
            }
        }
    }
    
    private func checkForCriticalAlerts() {
        criticalAlert = alertService.checkForCriticalAlerts(
            latestReading: latestGlucoseReading,
            isConnected: isConnectedDevice,
            lastSiteChange: lastSiteChange
        )
    }
    
    func dismissCriticalAlert() {
        criticalAlert = nil
    }
    
    // MARK: - Real Alert Actions (REPLACED PRINT STATEMENTS)
    func handleCriticalAlertAction() {
        guard let alert = criticalAlert else { return }
        let action = alertService.handleAlertAction(alert)
        
        switch action {
        case .showAddCarb:
            showAddCarbSheet = true
        case .showKetoneInfo:
            showKetoneInfoSheet = true  // REPLACED: print("Show ketone...")
        case .showDeviceTroubleshooting:
            showTroubleshootingSheet = true  // REPLACED: print("Show device...")
        case .showSiteChange:
            showAddSiteChangeSheet = true
        }
    }
}
