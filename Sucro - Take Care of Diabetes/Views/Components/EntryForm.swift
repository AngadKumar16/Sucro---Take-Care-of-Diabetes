//
//  EntryForm.swift
//  Sucro - Take Care of Diabetes
//
//  The sheet every add and edit form shares: Cancel and Save in the
//  navigation bar, a discard check when there are unsaved changes, and a
//  success haptic on save.
//

import SwiftUI
import UIKit

struct EntryForm<Content: View>: View {
    let title: String
    var saveTitle = "Save"
    let canSave: Bool
    let hasChanges: Bool
    /// Saves the entry. Return false to keep the form open.
    let onSave: () -> Bool
    var onCancel: () -> Void = {}
    @ViewBuilder var content: Content

    @Environment(\.dismiss) private var dismiss
    @State private var confirmDiscard = false
    @State private var saveFailed = false

    var body: some View {
        NavigationStack {
            Form {
                content
            }
            .instrumentBackground()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saveTitle, action: save)
                        .disabled(!canSave)
                }
            }
            .confirmationDialog("Discard this entry?", isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button("Discard Changes", role: .destructive, action: discard)
                Button("Keep Editing", role: .cancel) {}
            }
            .alert("Couldn't Save", isPresented: $saveFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Something went wrong saving this entry. Please try again.")
            }
        }
        .interactiveDismissDisabled(hasChanges)
    }

    private func cancel() {
        if hasChanges {
            confirmDiscard = true
        } else {
            discard()
        }
    }

    private func discard() {
        onCancel()
        dismiss()
    }

    private func save() {
        guard onSave() else {
            saveFailed = true
            return
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

// MARK: - Input helpers

/// Plausible ranges for logged values. Anything outside is almost
/// certainly a typo, so Save stays off and the form says why.
enum EntryLimits {
    static let carbGrams: ClosedRange<Double> = 1...500
    static let insulinUnits: ClosedRange<Double> = 0.05...100
    static let activityMinutes: ClosedRange<Double> = 1...600
    static let calories: ClosedRange<Double> = 0...5000
}

/// Reads a number typed in the user's locale ("5.5" or "5,5").
func parseNumber(_ text: String) -> Double? {
    let trimmed = text.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return nil }
    return try? Double(trimmed, format: .number)
}

/// A number formatted for editing: no grouping, up to two decimals.
func editableNumber(_ value: Double) -> String {
    value.formatted(.number.grouping(.never).precision(.fractionLength(0...2)))
}

/// A number field with its unit after it, the way Health shows them.
struct NumberField: View {
    let title: String
    let prompt: String
    @Binding var text: String
    let unit: String
    var allowsDecimals = true

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 4) {
                TextField(title, text: $text, prompt: Text(prompt))
                    .keyboardType(allowsDecimals ? .decimalPad : .numberPad)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                Text(unit)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// The message shown under an amount that's empty or out of range.
func rangeMessage(_ text: String, in range: ClosedRange<Double>, unit: String) -> String? {
    guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
    guard let value = parseNumber(text) else { return "Enter a number." }
    guard range.contains(value) else {
        let low = range.lowerBound.formatted(.number.precision(.fractionLength(0...2)))
        let high = range.upperBound.formatted(.number.precision(.fractionLength(0...2)))
        return "Enter a value from \(low) to \(high) \(unit)."
    }
    return nil
}
