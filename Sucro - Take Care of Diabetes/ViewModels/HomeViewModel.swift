//
//  HomeViewModel.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import Foundation
import CoreData

@MainActor
@Observable
class HomeViewModel: BaseViewModel {
    // MARK: - Published Properties
    var latestGlucoseReading: GlucoseReading?
    /// Readings in the Home chart's window, oldest first.
    var recentReadings: [GlucoseReading] = []
    var todayReadingCount = 0
    /// How far back the Home chart reaches.
    static let chartWindow: TimeInterval = 6 * 3600
    var todayInsulinTotal: Double = 0.0
    var todayCarbTotal: Double = 0.0
    var insulinOnBoard: Double = 0.0
    var timelineEvents: [TimelineEvent] = []
    /// Today's Plan, straight from the reminder service so snoozes and
    /// completions show immediately.
    var upcomingReminders: [Reminder] { reminderService.upcomingReminders }
    var smartSuggestion: String?
    var lastSiteChange: SiteChange?
    var criticalAlert: AlertType?
    /// Id of the banner the user closed; it stays hidden until the alert is
    /// about a different event.
    private var dismissedAlertID: String?
    
    // MARK: - Navigation State
    var showAddGlucoseSheet = false
    var showAddCarbSheet = false
    var showQuickBolusSheet = false
    var showAddSiteChangeSheet = false
    /// The event being edited or annotated.
    var selectedEvent: TimelineEvent?
    /// The event whose detail sheet is open.
    var detailEvent: TimelineEvent?
    var showNoteInput = false
    var noteEventTitle: String = ""
    
    // MARK: - Edit and Alert Sheets
    var editOperation: DraftOperation<NSManagedObject>?
    var showKetoneInfoSheet = false
    var showTroubleshootingSheet = false
    
    // MARK: - Services
    private let dataService = DataService.shared
    private let timelineService = TimelineService.shared
    private let alertService = AlertService.shared
    private let reminderService = ReminderService.shared
    private let settings = SettingsStore.shared


    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }
    
    // MARK: - Navigation Actions
    
    func logGlucose() {
        showAddGlucoseSheet = true
    }

    func logMeal() {
        showAddCarbSheet = true
    }

    /// Logs a one-tap preset meal (Breakfast/Lunch/Dinner) directly, without
    /// opening the full carb-entry form. Mirrors to Apple Health.
    func logMeal(preset: MealTemplate) {
        let timestamp = Date()
        let entry = CarbEntry(context: viewContext)
        entry.id = UUID()
        entry.grams = preset.carbs
        entry.mealType = MealType(stored: preset.name)?.rawValue ?? preset.name
        entry.timestamp = timestamp

        save()
        HealthKitManager.shared.saveCarbohydrateIntake(preset.carbs, timestamp: timestamp)
        fetchLatestData()
    }
        
    func quickBolus() {
        showQuickBolusSheet = true
    }
    
    func changeSite() {
        showAddSiteChangeSheet = true
    }
    
    func showEventDetails(_ event: TimelineEvent) {
        selectedEvent = event
        detailEvent = event
    }
    
    // MARK: - Editing
    func editEvent(_ event: TimelineEvent) {
        detailEvent = nil
        guard let objectID = event.objectID,
              let object = try? viewContext.existingObject(with: objectID) else { return }
        editOperation = DraftOperation(
            withExistingObject: object,
            inParentContext: viewContext,
            onSave: { [weak self] in
                self?.fetchLatestData()
            }
        )
    }

    func deleteEvent(_ event: TimelineEvent) {
        guard let objectID = event.objectID else { return }
        if dataService.delete(objectID, context: viewContext) {
            selectedEvent = nil
            detailEvent = nil
            fetchLatestData()
        }
    }

    func showAddNote(for event: TimelineEvent) {
        noteEventTitle = event.title
        selectedEvent = event
        showNoteInput = true
    }

    func saveNote(_ note: String) {
        guard let objectID = selectedEvent?.objectID else { return }
        if dataService.appendNote(note, to: objectID, context: viewContext) {
            showNoteInput = false
            fetchTimelineEvents()
        }
    }

    // MARK: - Reminder Actions
    func snoozeReminder(_ reminder: Reminder, minutes: Int = 15) {
        reminderService.snooze(reminder, minutes: minutes)
    }

    func completeReminder(_ reminder: Reminder) {
        reminderService.complete(reminder)
    }
    
    // MARK: - Data Fetching

    /// Refreshes once a minute until the calling task is cancelled, so the
    /// banner, IOB and reminders stay current while Home is on screen (for
    /// example, a CGM gap shows up without a manual refresh).
    func refreshWhileVisible() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(60))
            guard !Task.isCancelled else { return }
            fetchLatestData()
        }
    }
    
    func fetchLatestData() {
        latestGlucoseReading = dataService.fetchLatestGlucoseReading(context: viewContext)
        let now = Date()
        recentReadings = dataService.fetchGlucoseReadings(
            context: viewContext,
            in: DateInterval(start: now.addingTimeInterval(-Self.chartWindow), end: now)
        )
        todayReadingCount = dataService.fetchGlucoseReadings(
            context: viewContext,
            in: DateInterval(start: Calendar.current.startOfDay(for: now), end: now)
        ).count
        
        let totals = dataService.fetchTodayTotals(context: viewContext)
        todayInsulinTotal = totals.insulin
        todayCarbTotal = totals.carbs
        
        insulinOnBoard = dataService.calculateIOB(context: viewContext)
        lastSiteChange = dataService.fetchLastSiteChange(context: viewContext)
        
        fetchTimelineEvents()
        reminderService.refresh(context: viewContext)
        generateSmartSuggestion()
        checkForCriticalAlerts()
    }
    
    private func fetchTimelineEvents() {
        timelineEvents = timelineService.buildTimeline(context: viewContext, hoursBack: 12)
    }
    
    private func generateSmartSuggestion() {
        smartSuggestion = nil

        if let latest = latestGlucoseReading,
           let timestamp = latest.timestamp,
           Date().timeIntervalSince(timestamp) <= 30 * 60,
           settings.zone(for: latest.value) == .high,
           GlucoseTrend(stored: latest.trend)?.isRising == true {
            smartSuggestion = "Glucose is high and still rising. Check ketones."
            return
        }

        // A day before the site is due. Once it's due, the banner takes over.
        if let lastChange = lastSiteChange, let changed = lastChange.timestamp {
            let rotationDays = SiteLocation(stored: lastChange.location)?.rotationDays ?? 3
            let daysSince = Calendar.current.dateComponents([.day], from: changed, to: Date()).day ?? 0
            if daysSince == rotationDays - 1 {
                smartSuggestion = "Your site is \(daysSince) \(daysSince == 1 ? "day" : "days") old. Plan to change it tomorrow."
            }
        }
    }

    private func checkForCriticalAlerts() {
        let alert = alertService.evaluate(context: viewContext)
        let id = alert?.id(readingDate: latestGlucoseReading?.timestamp)
        criticalAlert = (id != nil && id == dismissedAlertID) ? nil : alert
    }

    func dismissCriticalAlert() {
        dismissedAlertID = criticalAlert?.id(readingDate: latestGlucoseReading?.timestamp)
        criticalAlert = nil
    }

    // MARK: - Alert Actions
    func handleCriticalAlertAction() {
        guard let alert = criticalAlert else { return }
        let action = alertService.handleAlertAction(alert)
        
        switch action {
        case .showAddCarb:
            showAddCarbSheet = true
        case .showKetoneInfo:
            showKetoneInfoSheet = true
        case .showDeviceTroubleshooting:
            showTroubleshootingSheet = true
        case .showSiteChange:
            showAddSiteChangeSheet = true
        }
    }
}
