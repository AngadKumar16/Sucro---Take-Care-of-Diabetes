//
//  LogViewModel.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import Foundation
import CoreData

@MainActor
@Observable
class LogViewModel: BaseViewModel {
    var glucoseReadings: [GlucoseReading] = []
    var carbEntries: [CarbEntry] = []
    var insulinEntries: [InsulinEntry] = []
    var activityEntries: [ActivityEntry] = []
    var selectedDate: Date = Date()
    /// Bumped on every fetch. A refetch usually returns the same managed
    /// objects, which Observation treats as "no change", so views read this
    /// to redraw rows whose fields (notes, values) changed underneath.
    private(set) var revision = 0
    var showAddGlucose = false
    var showAddCarbs = false
    var showAddInsulin = false
    var showAddActivity = false
    /// The entry being edited, if any.
    var editOperation: DraftOperation<NSManagedObject>?

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
        revision += 1
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

    func addCarbEntry(grams: Double, mealType: String?, foodItems: String?, notes: String?, timestamp: Date = Date()) {
        let entry = CarbEntry(context: viewContext)
        entry.id = UUID()
        entry.grams = grams
        entry.mealType = mealType
        entry.foodItems = foodItems
        entry.timestamp = timestamp
        entry.notes = notes

        save()
        HealthKitManager.shared.saveCarbohydrateIntake(grams, timestamp: timestamp)
        fetchEntriesForDate(selectedDate)
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
        if DataService.shared.delete(object.objectID, context: viewContext) {
            entriesChanged()
        }
    }

    /// Refreshes the list and anything computed from the logged data.
    private func entriesChanged() {
        AlertService.shared.evaluate(context: viewContext)
        ReminderService.shared.refresh(context: viewContext)
        fetchEntriesForDate(selectedDate)
    }
}
