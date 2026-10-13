//
//  KetoneFields.swift
//  DiabetesCare
//
//  Logging a ketone check: from a blood meter or a urine strip. The
//  footer says what the level usually means; the person's sick-day plan
//  from their care team comes first.
//

import SwiftUI
import CoreData

/// Plausible blood ketone values, mmol/L.
let ketoneBloodRange: ClosedRange<Double> = 0...10

struct KetoneFields: View {
    @Binding var method: KetoneMethod
    @Binding var valueText: String
    @Binding var urine: UrineKetones
    @Binding var timestamp: Date
    @Binding var notes: String
    var focus: FocusState<Bool>.Binding

    private var level: KetoneZone? {
        switch method {
        case .blood: parseNumber(valueText).flatMap { ketoneBloodRange.contains($0) ? KetoneZone(value: $0, method: .blood) : nil }
        case .urine: KetoneZone(value: Double(urine.rawValue), method: .urine)
        }
    }

    var body: some View {
        Section {
            Picker("Checked with", selection: $method) {
                ForEach(KetoneMethod.allCases, id: \.self) { Text($0.name).tag($0) }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
            switch method {
            case .blood:
                NumberField(title: "Ketones", prompt: "0.0", text: $valueText, unit: "mmol/L")
                    .focused(focus)
                    .accessibilityIdentifier("ketoneValue")
            case .urine:
                Picker("Strip color", selection: $urine) {
                    ForEach(UrineKetones.allCases, id: \.self) { Text($0.name).tag($0) }
                }
            }
        } footer: {
            if let level {
                Label("\(level.name). \(level.guidance)", systemImage: level >= .high ? "exclamationmark.triangle.fill" : "info.circle")
                    .foregroundStyle(level >= .high ? Theme.vermilion : Theme.soft)
            } else if method == .blood, let message = rangeMessage(valueText, in: ketoneBloodRange, unit: "mmol/L") {
                Text(message).foregroundStyle(.red)
            }
        }
        .listRowBackground(Theme.card)
        TimeAndNotesSections(timestamp: $timestamp, notes: $notes)
    }
}

struct AddKetoneView: View {
    @Environment(LogViewModel.self) private var viewModel
    @State private var method = KetoneMethod.blood
    @State private var valueText = ""
    @State private var urine = UrineKetones.negative
    @State private var timestamp = Date()
    @State private var notes = ""
    @FocusState private var focused: Bool

    private var value: Double? {
        switch method {
        case .blood: parseNumber(valueText).flatMap { ketoneBloodRange.contains($0) ? $0 : nil }
        case .urine: Double(urine.rawValue)
        }
    }

    var body: some View {
        EntryForm(title: "Add Ketones", canSave: value != nil, hasChanges: !valueText.isEmpty || !notes.isEmpty) {
            guard let value else { return false }
            viewModel.addKetoneReading(value: value, method: method, notes: notes.isEmpty ? nil : notes, timestamp: timestamp)
            return true
        } content: {
            KetoneFields(method: $method, valueText: $valueText, urine: $urine, timestamp: $timestamp, notes: $notes, focus: $focused)
        }
        .defaultFocus($focused, true)
    }
}

struct EditKetoneView: View {
    let entry: KetoneReading
    let operation: DraftOperation<NSManagedObject>

    @State private var method = KetoneMethod.blood
    @State private var valueText = ""
    @State private var urine = UrineKetones.negative
    @State private var timestamp = Date()
    @State private var notes = ""
    @State private var original: [AnyHashable] = []
    @FocusState private var focused: Bool

    private var current: [AnyHashable] { [method, valueText, urine, timestamp, notes] }

    private var value: Double? {
        switch method {
        case .blood: parseNumber(valueText).flatMap { ketoneBloodRange.contains($0) ? $0 : nil }
        case .urine: Double(urine.rawValue)
        }
    }

    var body: some View {
        EntryForm(
            title: "Edit Ketones",
            canSave: value != nil,
            hasChanges: !original.isEmpty && current != original,
            onSave: save,
            onCancel: operation.cancel
        ) {
            KetoneFields(method: $method, valueText: $valueText, urine: $urine, timestamp: $timestamp, notes: $notes, focus: $focused)
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard original.isEmpty else { return }
        method = entry.ketoneMethod
        if method == .blood {
            valueText = editableNumber(entry.value)
        } else {
            urine = UrineKetones(rawValue: Int(entry.value.rounded())) ?? .negative
        }
        timestamp = entry.timestamp ?? Date()
        notes = entry.notes ?? ""
        original = current
    }

    private func save() -> Bool {
        guard let value else { return false }
        entry.method = method.rawValue
        entry.value = value
        entry.timestamp = timestamp
        entry.notes = notes.isEmpty ? nil : notes
        return operation.save()
    }
}
