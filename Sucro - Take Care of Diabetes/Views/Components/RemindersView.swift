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
    let onSnooze: (Reminder) -> Void
    let onComplete: (Reminder) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Plan")
                .font(.headline)
                .foregroundColor(.primary)
            
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
                            onSnooze: { onSnooze(reminder) },
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
                .foregroundColor(.yellow)
                .frame(width: 32, height: 32)
                .background(Color.yellow.opacity(0.2))
                .clipShape(Circle())
            
            Text(suggestion)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ReminderCard: View {
    let reminder: Reminder
    let onSnooze: () -> Void
    let onComplete: () -> Void
    
    @State private var showingSnoozeOptions = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Reminder Icon
            Image(systemName: reminderIcon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(reminderColor)
                .clipShape(Circle())
            
            // Reminder Details
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(reminder.time, formatter: reminderTimeFormatter)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 8) {
                Button(action: onSnooze) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onComplete) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
                        .frame(width: 32, height: 32)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
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
            Button("15 minutes") { snoozeFor(15) }
            Button("30 minutes") { snoozeFor(30) }
            Button("1 hour") { snoozeFor(60) }
            Button("2 hours") { snoozeFor(120) }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("How long would you like to snooze this reminder?")
        }
    }
    
    private var reminderIcon: String {
        switch reminder.type {
        case .siteChange:
            return "bandage.fill"
        case .deviceCheck:
            return "iphone.radiowaves.left.and.right"
        case .medication:
            return "pills.fill"
        }
    }
    
    private var reminderColor: Color {
        switch reminder.type {
        case .siteChange:
            return .purple
        case .deviceCheck:
            return .blue
        case .medication:
            return .green
        }
    }
    
    private func snoozeFor(_ minutes: Int) {
        // In a real app, this would update the reminder time
        print("Snoozing for \(minutes) minutes")
    }
}

struct EmptyRemindersView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 32))
                .foregroundColor(.green)
            
            Text("All caught up!")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("No upcoming reminders")
                .font(.caption)
                .foregroundColor(.secondary)
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
                Reminder(title: "Change infusion site", time: Date().addingTimeInterval(3600), type: .siteChange),
                Reminder(title: "Check CGM sensor", time: Date().addingTimeInterval(7200), type: .deviceCheck),
                Reminder(title: "Take medication", time: Date().addingTimeInterval(10800), type: .medication)
            ],
            suggestion: "Consider changing the site - 2 days since last change",
            onSnooze: { _ in },
            onComplete: { _ in }
        )
        
        RemindersView(
            reminders: [],
            suggestion: nil,
            onSnooze: { _ in },
            onComplete: { _ in }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
