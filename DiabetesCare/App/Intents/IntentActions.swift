//
//  IntentActions.swift
//  DiabetesCare
//
//  What Siri, Shortcuts, widgets, controls and the watch actually do in
//  the app. Logging goes through the same view model the forms use, so
//  Health mirroring, alerts and the undo toast all behave the same.
//

import CoreData
import Foundation

@MainActor
enum IntentActions {
    private static var context: NSManagedObjectContext { PersistenceController.shared.container.viewContext }

    static func logFastSugar(grams: Double) async {
        LowTreatmentService.logFastCarbs(grams: grams, context: context)
    }

    static func logCarbs(grams: Double, context: NSManagedObjectContext? = nil) {
        LogViewModel(context: context ?? Self.context).addCarbEntry(
            grams: grams, mealType: MealType.likely(at: .now).rawValue, foodItems: nil, notes: nil
        )
    }

    static func logGlucose(mgdl: Double, context: NSManagedObjectContext? = nil) {
        LogViewModel(context: context ?? Self.context).addGlucoseReading(
            value: mgdl, unit: "mg/dL", context: GlucoseContext.likely(at: .now).rawValue, notes: nil
        )
    }

    static func logInsulin(units: Double) {
        LogViewModel(context: context).addInsulinEntry(
            units: units, type: InsulinType.bolus.rawValue, deliveryMethod: SettingsStore.shared.lastDeliveryMethod.rawValue, notes: nil
        )
    }

    static func open(_ screen: AppScreen) async {
        AppRouter.shared.pending = switch screen {
        case .logCarbs: .logCarbs
        case .logGlucose: .logGlucose
        case .getHelp: .getHelp
        case .trends: .trends
        }
    }

    /// "120 mg/dL, steady, 4 minutes ago." for Siri.
    static func glucoseSentence(now: Date = Date()) -> String {
        let snapshot = GlanceWriter.snapshot(context: context, settings: .shared, now: now)
        guard let latest = snapshot.latest else {
            return String(localized: "There's no glucose reading yet. Log one in DiabetesCare.")
        }
        let value = "\(snapshot.value(latest.mgdl)) \(snapshot.unit)"
        let trend = GlucoseTrend(stored: snapshot.trend).map { ", \($0.description.lowercased())" } ?? ""
        let age = now.timeIntervalSince(latest.date) < 60
            ? String(localized: "just now")
            : latest.date.formatted(.relative(presentation: .named))
        let zone = snapshot.zone(latest.mgdl).name.lowercased()
        return String(localized: "\(value)\(trend), \(zone), \(age).")
    }
}
