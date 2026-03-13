//
//  RealReminderService.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import UserNotifications
import CoreData
import SwiftUI
import Combine

class RealReminderService: NSObject, ObservableObject {
    static let shared = RealReminderService()
    private let center = UNUserNotificationCenter.current()
    
    @Published var upcomingReminders: [Reminder] = []
    
    override init() {
        super.init()
        requestAuthorization()
        loadPendingNotifications()
    }
    
    private func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func scheduleReminders(
        for siteChange: SiteChange?,
        insulinOnBoard: Double,
        context: NSManagedObjectContext
    ) {
        center.removeAllPendingNotificationRequests()
        upcomingReminders.removeAll()
        
        var reminders: [Reminder] = []
        
        if let lastChange = siteChange?.timestamp {
            let threeDaysLater = Calendar.current.date(byAdding: .day, value: 3, to: lastChange)!
            if threeDaysLater > Date() {
                let reminder = Reminder(
                    title: "Site Change Due",
                    time: threeDaysLater,
                    type: .siteChange,
                    notes: "It's been 3 days since your last site change"
                )
                reminders.append(reminder)
                scheduleNotification(for: reminder)
            }
        }
        
        if insulinOnBoard > 0 {
            let checkTime = Date().addingTimeInterval(2 * 60 * 60)
            let reminder = Reminder(
                title: "Check Glucose",
                time: checkTime,
                type: .deviceCheck,  // Using existing type
                notes: "Check your glucose - insulin may still be active"
            )
            reminders.append(reminder)
            scheduleNotification(for: reminder)
        }
        
        checkForMissedReadings(context: context) { [weak self] missedReadingReminder in
            if let reminder = missedReadingReminder {
                reminders.append(reminder)
                self?.scheduleNotification(for: reminder)
            }
            // FIX: Use sorted(by:) instead of sorted(using:)
            self?.upcomingReminders = reminders.sorted(by: { $0.time < $1.time })
        }
    }
    
    private func scheduleNotification(for reminder: Reminder) {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.notes ?? "Reminder from Sucro"
        content.sound = .default
        // FIX: Convert UUID to String
        content.userInfo = ["reminderId": reminder.id.uuidString, "type": reminder.type.rawValue]
        
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminder.time
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // FIX: Use uuidString as identifier
        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    private func loadPendingNotifications() {
        center.getPendingNotificationRequests { [weak self] requests in
            DispatchQueue.main.async {
                self?.upcomingReminders = requests.compactMap { request in
                    guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
                          let nextTriggerDate = trigger.nextTriggerDate() else { return nil }
                    
                    // FIX: Parse UUID from string, handle missing type
                    let reminderId = UUID(uuidString: request.identifier) ?? UUID()
                    let typeRaw = request.content.userInfo["type"] as? String ?? ""
                    let type = ReminderType(rawValue: typeRaw) ?? .deviceCheck
                    
                    return Reminder(
                        title: request.content.title,
                        time: nextTriggerDate,
                        type: type,
                        notes: request.content.body
                    )
                }.sorted(by: { $0.time < $1.time })  // FIX: Use sorted(by:)
            }
        }
    }
    
    private func checkForMissedReadings(
        context: NSManagedObjectContext,
        completion: @escaping (Reminder?) -> Void
    ) {
        let request: NSFetchRequest<GlucoseReading> = GlucoseReading.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = 1
        
        do {
            let readings = try context.fetch(request)
            if let lastReading = readings.first?.timestamp {
                let timeSince = Date().timeIntervalSince(lastReading)
                if timeSince > 20 * 60 {
                    let reminder = Reminder(
                        title: "Missed Glucose Reading",
                        time: Date().addingTimeInterval(60),
                        type: .deviceCheck,  // Using existing type
                        notes: "No glucose data for 20+ minutes. Check sensor connection."
                    )
                    completion(reminder)
                    return
                }
            }
            completion(nil)
        } catch {
            print("Error checking readings: \(error)")
            completion(nil)
        }
    }
    
    func snoozeReminder(_ reminder: Reminder, minutes: Int) {
        // FIX: Use uuidString
        center.removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
        
        let newDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        let newReminder = Reminder(
            title: reminder.title,
            time: newDate,
            type: reminder.type,
            notes: reminder.notes
        )
        
        scheduleNotification(for: newReminder)
        loadPendingNotifications()
    }
    
    func completeReminder(_ reminder: Reminder) {
        // FIX: Use uuidString
        center.removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
        upcomingReminders.removeAll { $0.id == reminder.id }
    }
}
