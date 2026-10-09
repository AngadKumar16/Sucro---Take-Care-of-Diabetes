//
//  EntryFields.swift
//  Sucro - Take Care of Diabetes
//
//  The form sections for each kind of entry. Add and edit screens both use
//  these, so they always offer the same fields and store the same values.
//

import SwiftUI

/// Shared time and notes sections at the bottom of every entry form.
struct TimeAndNotesSections: View {
    @Binding var timestamp: Date
    @Binding var notes: String
    var timeLabel = "Time"
    /// Shows the time without letting it change.
    var isTimeEditable = true

    var body: some View {
        Section {
            if isTimeEditable {
                DatePicker(timeLabel, selection: $timestamp, in: ...Date.now)
            } else {
                LabeledContent(timeLabel, value: timestamp.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .listRowBackground(Theme.card)
        Section("Notes") {
            TextField("Optional", text: $notes, axis: .vertical)
                .lineLimit(2...6)
        }
        .listRowBackground(Theme.card)
    }
}

struct GlucoseFields: View {
    @Environment(SettingsStore.self) private var settings
    @Binding var valueText: String
    @Binding var context: GlucoseContext
    @Binding var timestamp: Date
    @Binding var notes: String
    var focus: FocusState<Bool>.Binding
    /// Set for readings imported from Apple Health: the value and time belong
    /// to the app that recorded them, so they're shown but not editable.
    var importedFromHealth = false

    var body: some View {
        Section {
            if importedFromHealth {
                LabeledContent("Glucose", value: "\(valueText) \(settings.glucoseUnit)")
            } else {
                NumberField(title: "Glucose", prompt: "Enter value", text: $valueText, unit: settings.glucoseUnit,
                            allowsDecimals: settings.glucoseUnit == "mmol/L")
                    .focused(focus)
            }
            Picker("When", selection: $context) {
                ForEach(GlucoseContext.allCases, id: \.self) { context in
                    Text(context.rawValue).tag(context)
                }
            }
        } footer: {
            if importedFromHealth {
                Text("From Apple Health. To change the value, edit it in the app that recorded it.")
            } else if let message = glucoseMessage(valueText, settings: settings) {
                Text(message).foregroundStyle(.red)
            }
        }
        .listRowBackground(Theme.card)
        TimeAndNotesSections(timestamp: $timestamp, notes: $notes, isTimeEditable: !importedFromHealth)
    }
}

/// The plausible glucose range in the user's unit.
@MainActor
func glucoseDisplayRange(_ settings: SettingsStore) -> ClosedRange<Double> {
    let range = SettingsStore.plausibleGlucose
    return settings.displayGlucose(range.lowerBound)...settings.displayGlucose(range.upperBound)
}

@MainActor
func glucoseMessage(_ text: String, settings: SettingsStore) -> String? {
    rangeMessage(text, in: glucoseDisplayRange(settings), unit: settings.glucoseUnit)
}

/// mg/dL for a typed glucose value, or nil if it's empty or implausible.
@MainActor
func parsedGlucose(_ text: String, settings: SettingsStore) -> Double? {
    guard let value = parseNumber(text) else { return nil }
    let mgdl = settings.mgdl(fromDisplay: value)
    // Compare after rounding so 1.1 mmol/L (19.8 mg/dL) isn't rejected
    // for a rounding hair.
    return SettingsStore.plausibleGlucose.contains(mgdl.rounded()) ? mgdl : nil
}

struct CarbFields: View {
    @Binding var gramsText: String
    @Binding var mealType: MealType
    @Binding var foodItems: String
    @Binding var timestamp: Date
    @Binding var notes: String
    var focus: FocusState<Bool>.Binding

    var body: some View {
        Section {
            NumberField(title: "Carbs", prompt: "0", text: $gramsText, unit: "g")
                .focused(focus)
            Picker("Meal", selection: $mealType) {
                ForEach(MealType.allCases, id: \.self) { meal in
                    Text(meal.rawValue).tag(meal)
                }
            }
            TextField("What did you eat? (optional)", text: $foodItems, axis: .vertical)
                .lineLimit(1...4)
        } footer: {
            if let message = rangeMessage(gramsText, in: EntryLimits.carbGrams, unit: "g") {
                Text(message).foregroundStyle(.red)
            }
        }
        .listRowBackground(Theme.card)
        TimeAndNotesSections(timestamp: $timestamp, notes: $notes)
    }
}

struct InsulinFields: View {
    @Binding var unitsText: String
    @Binding var type: InsulinType
    @Binding var deliveryMethod: DeliveryMethod
    @Binding var timestamp: Date
    @Binding var notes: String
    var focus: FocusState<Bool>.Binding

    var body: some View {
        Section {
            NumberField(title: "Dose", prompt: "0", text: $unitsText, unit: "U")
                .focused(focus)
            Picker("Type", selection: $type) {
                ForEach(InsulinType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            Picker("Given With", selection: $deliveryMethod) {
                ForEach(DeliveryMethod.allCases, id: \.self) { method in
                    Text(method.rawValue).tag(method)
                }
            }
        } footer: {
            if let message = rangeMessage(unitsText, in: EntryLimits.insulinUnits, unit: "U") {
                Text(message).foregroundStyle(.red)
            } else {
                Text("This records a dose. It doesn't control a pump.")
            }
        }
        .listRowBackground(Theme.card)
        TimeAndNotesSections(timestamp: $timestamp, notes: $notes)
    }
}

enum ActivityOptions {
    static let types = ["Walking", "Running", "Cycling", "Swimming", "Gym", "Yoga", "Other"]
    static let intensities = ["Light", "Moderate", "Vigorous"]
}

struct ActivityFields: View {
    @Binding var activityType: String
    @Binding var durationText: String
    @Binding var intensity: String
    @Binding var caloriesText: String
    @Binding var timestamp: Date
    @Binding var notes: String
    var focus: FocusState<Bool>.Binding

    var body: some View {
        Section {
            Picker("Activity", selection: $activityType) {
                ForEach(options(ActivityOptions.types, keeping: activityType), id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            NumberField(title: "Duration", prompt: "0", text: $durationText, unit: "min", allowsDecimals: false)
                .focused(focus)
            Picker("Intensity", selection: $intensity) {
                ForEach(options(ActivityOptions.intensities, keeping: intensity), id: \.self) { intensity in
                    Text(intensity).tag(intensity)
                }
            }
            NumberField(title: "Calories", prompt: "Optional", text: $caloriesText, unit: "kcal", allowsDecimals: false)
        } footer: {
            if let message = rangeMessage(durationText, in: EntryLimits.activityMinutes, unit: "minutes")
                ?? rangeMessage(caloriesText, in: EntryLimits.calories, unit: "kcal") {
                Text(message).foregroundStyle(.red)
            }
        }
        .listRowBackground(Theme.card)
        TimeAndNotesSections(timestamp: $timestamp, notes: $notes, timeLabel: "Started")
    }

    /// The fixed choices, plus the current value if an older entry stored
    /// something else, so the picker never shows blank.
    private func options(_ base: [String], keeping current: String) -> [String] {
        base.contains(current) || current.isEmpty ? base : base + [current]
    }
}

struct SiteFields: View {
    @Binding var location: SiteLocation
    @Binding var timestamp: Date
    @Binding var notes: String

    var body: some View {
        Section {
            Picker("Location", selection: $location) {
                ForEach(SiteLocation.allCases, id: \.self) { location in
                    Text(location.rawValue).tag(location)
                }
            }
            LabeledContent("Change Every", value: "\(location.rotationDays) days")
        } footer: {
            Text("You'll get a reminder when this site is due.")
        }
        .listRowBackground(Theme.card)
        TimeAndNotesSections(timestamp: $timestamp, notes: $notes, timeLabel: "Changed")
    }
}
