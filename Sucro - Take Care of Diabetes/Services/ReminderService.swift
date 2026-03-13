//
//  ReminderService.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//


//
//  ReminderService.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import Foundation
import UserNotifications

class ReminderService {
    static let shared = ReminderService()
    
    private init() {}
    
    func generateMockReminders() -> [Reminder] {
        return [
            Reminder(title: "Change infusion site", time: Date().addingTimeInterval(3600), type: .siteChange),
            Reminder(title: "Check CGM sensor", time: Date().addingTimeInterval(7200), type: .deviceCheck)
        ]
    }
    
    func snoozeReminder(_ reminder: Reminder, minutes: Int = 15) {
        let newTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
        
        let content = UNMutableNotificationContent()
        content.title = "Snoozed: \(reminder.title)"
        content.body = "Reminder snoozed until \(newTime.formatted(date: .omitted, time: .shortened))"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let request = UNNotificationRequest(
            identifier: "snoozed-\(reminder.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling snoozed reminder: \(error.localizedDescription)")
            }
        }
    }
    
    func completeReminder(_ reminder: Reminder, from reminders: inout [Reminder]) {
        reminders.removeAll { $0.id == reminder.id }
        
        // Cancel notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let matchingIds = requests
                .filter { $0.identifier.contains(reminder.id.uuidString) }
                .map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: matchingIds)
        }
    }
}