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
    // MARK: - Published Properties
    @Published var latestGlucoseReading: GlucoseReading?
    @Published var recentReadings: [GlucoseReading] = []
    @Published var todayInsulinTotal: Double = 0.0
    @Published var todayCarbTotal: Double = 0.0
    @Published var insulinOnBoard: Double = 0.0
    @Published var batteryLevel: Double = 0.85
    @Published var lastSyncTime: Date? = Date().addingTimeInterval(-300)
    @Published var isConnectedDevice: Bool = true
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
    @Published var showEditSheet = false
    
    // MARK: - Services
    private let dataService = DataService.shared
    private let timelineService = TimelineService.shared
    private let alertService = AlertService.shared
    private let reminderService = ReminderService.shared
    
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
        selectedEvent = event
        showEditSheet = true
        showEventDetail = false
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
    
    func snoozeReminder(_ reminder: Reminder) {
        reminderService.snoozeReminder(reminder, minutes: 15)
        reminderService.completeReminder(reminder, from: &upcomingReminders)
    }
    
    func completeReminder(_ reminder: Reminder) {
        reminderService.completeReminder(reminder, from: &upcomingReminders)
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
    }
    
    private func fetchTimelineEvents() {
        timelineEvents = timelineService.buildTimeline(context: viewContext, hoursBack: 12)
    }
    
    private func fetchReminders() {
        upcomingReminders = reminderService.generateMockReminders()
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
    
    func handleCriticalAlertAction() {
        guard let alert = criticalAlert else { return }
        let action = alertService.handleAlertAction(alert)
        
        switch action {
        case .showAddCarb:
            showAddCarbSheet = true
        case .showKetoneInfo:
            print("Show ketone checking information")
        case .showDeviceTroubleshooting:
            print("Show device troubleshooting steps")
        case .showSiteChange:
            showAddSiteChangeSheet = true
        }
    }
}
