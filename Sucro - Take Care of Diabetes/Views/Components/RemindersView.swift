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
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Plan")
                .font(.headline)
                .foregroundStyle(.primary)
            
            // Smart Suggestion
            if let suggestion = suggestion {
                SuggestionCard(suggestion: suggestion)
            }
            
            // Upcoming Reminders
            if !reminders.isEmpty {
                LazyVStack(spacing: 8) {
                    ForEach(reminders.prefix(3)) { reminder in
                        ReminderCard(
                            reminder: reminder,
                            onSnooze: { minutes in onSnooze(reminder, minutes) },
                            onComplete: { onComplete(reminder) }
                        )
                    }
                }
            } else {
                EmptyRemindersView()
            }
        }
        .padding(.horizontal, 16)
    }
}

struct SuggestionCard: View {
    let suggestion: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.yellow)
                .frame(width: 32, height: 32)
                .background(Color.yellow.opacity(0.2))
                .clipShape(Circle())
            
            Text(suggestion)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                }
        )
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
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(reminder.type.tint)
                .clipShape(Circle())
            
            // Reminder Details
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                
                Text(reminder.time, formatter: reminderTimeFormatter)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
        )
        .confirmationDialog("Snooze Reminder", isPresented: $showingSnoozeOptions) {
            Button("15 minutes") { onSnooze(15) }
            Button("1 hour") { onSnooze(60) }
            Button("2 hours") { onSnooze(120) }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Snooze for how long?")
        }
    }

    private func showSnoozeOptions() {
        showingSnoozeOptions = true
    }
}

struct EmptyRemindersView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 32))
                .foregroundStyle(.green)
            
            Text("All caught up!")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            Text("No upcoming reminders")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
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
