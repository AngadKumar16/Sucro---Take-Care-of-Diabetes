//
//  RemindersView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI

struct RemindersView: View {
    let reminders: [Reminder]
    let suggestion: String?
    let onSnooze: (Reminder, Int) -> Void
    let onComplete: (Reminder) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeader("Today's Plan")

            if let suggestion {
                SuggestionCard(suggestion: suggestion)
            }

            if reminders.isEmpty {
                if suggestion == nil {
                    Label("All caught up. No reminders coming up.", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.multicolor)
                        .card()
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(reminders.prefix(3).enumerated()), id: \.element.id) { index, reminder in
                        if index > 0 {
                            Divider().padding(.leading, 60)
                        }
                        ReminderCard(
                            reminder: reminder,
                            onSnooze: { minutes in onSnooze(reminder, minutes) },
                            onComplete: { onComplete(reminder) }
                        )
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
            }
        }
    }
}

struct SuggestionCard: View {
    let suggestion: String

    var body: some View {
        Label {
            Text(suggestion)
                .font(.subheadline.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.15), in: .rect(cornerRadius: 16))
    }
}

struct ReminderCard: View {
    let reminder: Reminder
    let onSnooze: (Int) -> Void
    let onComplete: () -> Void

    @State private var showingSnoozeOptions = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Reminder Icon
            Image(systemName: reminder.type.icon)
                .font(.body.weight(.medium))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(reminder.type.tint.gradient, in: .circle)
                .accessibilityHidden(true)
            
            // Reminder Details
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text(reminder.time, formatter: reminderTimeFormatter)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 8) {
                Button("Snooze \(reminder.title)", systemImage: "clock.arrow.circlepath", action: showSnoozeOptions)
                    .labelStyle(.iconOnly)
                    .buttonStyle(ReminderIconButtonStyle(tint: .blue))

                Button("Mark \(reminder.title) done", systemImage: "checkmark.circle.fill", action: onComplete)
                    .labelStyle(.iconOnly)
                    .buttonStyle(ReminderIconButtonStyle(tint: .green))
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 4)
        .padding(.vertical, 4)
        .confirmationDialog("Snooze \(reminder.title)", isPresented: $showingSnoozeOptions, titleVisibility: .visible) {
            Button("15 minutes") { onSnooze(15) }
            Button("1 hour") { onSnooze(60) }
            Button("2 hours") { onSnooze(120) }
            Button("Cancel", role: .cancel) { }
        }
    }

    private func showSnoozeOptions() {
        showingSnoozeOptions = true
    }
}

private let reminderTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    VStack(spacing: 16) {
        RemindersView(
            reminders: [
                Reminder(title: "Site Change Due", time: Date().addingTimeInterval(3600), type: .siteChange),
                Reminder(title: "Check Glucose", time: Date().addingTimeInterval(7200), type: .glucoseCheck)
            ],
            suggestion: "Your site is 2 days old. Plan to change it soon.",
            onSnooze: { _, _ in },
            onComplete: { _ in }
        )
        
        RemindersView(
            reminders: [],
            suggestion: nil,
            onSnooze: { _, _ in },
            onComplete: { _ in }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
