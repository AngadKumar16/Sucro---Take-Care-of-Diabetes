//
//  LogViewModel.swift
//  DiabetesCare
//
//  Created by Angad Kumar on 3/11/26.
//

import Foundation
import OSLog
import CoreData

@MainActor
@Observable
class LogViewModel: BaseViewModel {
    var glucoseReadings: [GlucoseReading] = []
    var carbEntries: [CarbEntry] = []
    var insulinEntries: [InsulinEntry] = []
    var activityEntries: [ActivityEntry] = []
    var siteChanges: [SiteChange] = []
    var ketoneReadings: [KetoneReading] = []
    var selectedDate: Date = Date()
    /// Bumped on every fetch. A refetch usually returns the same managed
    /// objects, which Observation treats as "no change", so views read this
    /// to redraw rows whose fields (notes, values) changed underneath.
    private(set) var revision = 0
    var showAddGlucose = false
    var showAddCarbs = false
    var showAddInsulin = false
    var showAddActivity = false
    var showAddKetones = false
    /// The entry being edited, if any.
    var editOperation: DraftOperation<NSManagedObject>?
    /// Set when deleting fails, for the Log to show.
    var actionError: String?

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
        fetchSiteChanges(from: startOfDay, to: endOfDay)
        fetchKetones(from: startOfDay, to: endOfDay)
        revision += 1
    }
    
    private func fetchGlucoseReadings(from start: Date, to end: Date) {
        let request: NSFetchRequest<GlucoseReading> = GlucoseReading.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReading.timestamp, ascending: false)]
        
        do {
            glucoseReadings = try viewContext.fetch(request)
        } catch {
            Log.data.error("Error fetching glucose readings: \(String(describing: error), privacy: .public)")
        }
    }
    
    private func fetchCarbEntries(from start: Date, to end: Date) {
        let request: NSFetchRequest<CarbEntry> = CarbEntry.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CarbEntry.timestamp, ascending: false)]
        
        do {
            carbEntries = try viewContext.fetch(request)
        } catch {
            Log.data.error("Error fetching carb entries: \(String(describing: error), privacy: .public)")
        }
    }
    
    private func fetchInsulinEntries(from start: Date, to end: Date) {
        let request: NSFetchRequest<InsulinEntry> = InsulinEntry.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \InsulinEntry.timestamp, ascending: false)]
        
        do {
            insulinEntries = try viewContext.fetch(request)
        } catch {
            Log.data.error("Error fetching insulin entries: \(String(describing: error), privacy: .public)")
        }
    }
    
    private func fetchActivityEntries(from start: Date, to end: Date) {
        let request: NSFetchRequest<ActivityEntry> = ActivityEntry.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ActivityEntry.timestamp, ascending: false)]
        
        do {
            activityEntries = try viewContext.fetch(request)
        } catch {
            Log.data.error("Error fetching activity entries: \(String(describing: error), privacy: .public)")
        }
    }
    
    private func fetchSiteChanges(from start: Date, to end: Date) {
        let request: NSFetchRequest<SiteChange> = SiteChange.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SiteChange.timestamp, ascending: false)]

        do {
            siteChanges = try viewContext.fetch(request)
        } catch {
            Log.data.error("Error fetching site changes: \(String(describing: error), privacy: .public)")
        }
    }

    private func fetchKetones(from start: Date, to end: Date) {
        let request: NSFetchRequest<KetoneReading> = KetoneReading.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \KetoneReading.timestamp, ascending: false)]
        ketoneReadings = (try? viewContext.fetch(request)) ?? []
    }

    func addKetoneReading(value: Double, method: KetoneMethod, notes: String?, timestamp: Date = Date()) {
        let entry = KetoneReading(context: viewContext)
        entry.id = UUID()
        entry.value = value
        entry.method = method.rawValue
        entry.notes = notes
        entry.timestamp = timestamp
        save()
        fetchEntriesForDate(selectedDate)
        let level = entry.level
        ToastCenter.shared.show(
            String(localized: "Logged ketones: \(entry.displayValue) · \(level.name)"),
            kind: level >= .high ? .attention : .saved,
            haptic: level >= .high,
            undo: ToastCenter.undoInsert(entry.objectID, in: viewContext)
        )
    }

    func addGlucoseReading(value: Double, unit: String, context: String?, notes: String?, timestamp: Date = Date()) {
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
        let settings = SettingsStore.shared
        let zone = settings.zone(for: value)
        ToastCenter.shared.show(
            String(localized: "Logged \(settings.formattedGlucose(value)) · \(zone.name)"),
            kind: zone.needsAction ? .attention : .saved,
            haptic: zone.needsAction,
            undo: ToastCenter.undoInsert(reading.objectID, in: viewContext)
        )
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

    func addCarbEntry(grams: Double, mealType: String?, foodItems: String?, notes: String?, timestamp: Date = Date(), photo: Data? = nil) {
        let entry = CarbEntry(context: viewContext)
        entry.id = UUID()
        entry.grams = grams
        entry.mealType = mealType
        entry.foodItems = foodItems
        entry.timestamp = timestamp
        entry.notes = notes
        entry.photo = photo

        save()
        HealthKitManager.shared.saveCarbohydrateIntake(grams, timestamp: timestamp)
        fetchEntriesForDate(selectedDate)
        ToastCenter.shared.show(
            String(localized: "Logged \(grams.formatted(.number.precision(.fractionLength(0...1)))) g carbs"),
            haptic: false,
            undo: ToastCenter.undoInsert(entry.objectID, in: viewContext)
        )
    }

    func addInsulinEntry(units: Double, type: String?, deliveryMethod: String?, notes: String?, timestamp: Date = Date()) {
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
        ToastCenter.shared.show(
            String(localized: "Logged \(units.formatted(.number.precision(.fractionLength(0...2)))) U insulin"),
            haptic: false,
            undo: ToastCenter.undoInsert(entry.objectID, in: viewContext)
        )
    }

    func addActivityEntry(type: String?, duration: Int16, intensity: String?, caloriesBurned: Double, notes: String?, timestamp: Date = Date()) {
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
        ToastCenter.shared.show(
            String(localized: "Logged \(type ?? String(localized: "activity")), \(duration) min"),
            haptic: false,
            undo: ToastCenter.undoInsert(entry.objectID, in: viewContext)
        )
    }

    // MARK: - Day navigation

    var isShowingToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    /// Moves the day being shown, never past today.
    func moveDay(by days: Int) {
        let calendar = Calendar.current
        guard let date = calendar.date(byAdding: .day, value: days, to: selectedDate) else { return }
        selectedDate = min(date, Date())
        fetchEntriesForDate(selectedDate)
    }

    // MARK: - Editing

    func edit(_ object: NSManagedObject) {
        editOperation = DraftOperation(
            withExistingObject: object,
            inParentContext: viewContext,
            onSave: { [weak self] in
                self?.entriesChanged()
            }
        )
    }

    func deleteEntry(_ object: NSManagedObject) {
        let undo = ToastCenter.undoDelete(of: object)
        if DataService.shared.delete(object.objectID, context: viewContext) {
            entriesChanged()
            ToastCenter.shared.show(String(localized: "Entry deleted"), kind: .removed, undo: undo)
        } else {
            actionError = "This entry couldn't be deleted. Please try again."
        }
    }

    /// Refreshes the list and anything computed from the logged data.
    private func entriesChanged() {
        AlertService.shared.evaluate(context: viewContext)
        ReminderService.shared.refresh(context: viewContext)
        fetchEntriesForDate(selectedDate)
    }
}
