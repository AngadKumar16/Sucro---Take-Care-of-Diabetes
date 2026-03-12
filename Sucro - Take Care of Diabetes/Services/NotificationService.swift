//
//  NotificationService.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation
import UserNotifications
import Combine

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.authorizationStatus = granted ? .authorized : .denied
            }
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    // MARK: - Schedule Notifications
    
    func scheduleSiteChangeReminder(days: Int, completion: @escaping () -> Void) {
        let content = UNMutableNotificationContent()
        content.title = "Site Change Due"
        content.body = "It's been \(days) days since your last infusion site change."
        content.sound = .default
        content.categoryIdentifier = "SITE_CHANGE"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(days * 24 * 3600), repeats: false)
        
        let request = UNNotificationRequest(identifier: "site-change-\(UUID())", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { _ in
            completion()
        }
    }
    
    func scheduleCriticalGlucoseAlert(value: Double, isLow: Bool) {
        let content = UNMutableNotificationContent()
        content.title = isLow ? "LOW GLUCOSE" : "HIGH GLUCOSE"
        content.body = isLow ?
            "Glucose is \(Int(value)) mg/dL. Treat with 15g fast carbs." :
            "Glucose is \(Int(value)) mg/dL. Check for ketones."
        content.sound = .defaultCritical
        content.interruptionLevel = .critical
        
        let request = UNNotificationRequest(
            identifier: "critical-glucose-\(UUID())",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleDeviceOfflineAlert(deviceName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Device Offline"
        content.body = "\(deviceName) has not synced recently. Check connection."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "device-offline-\(UUID())",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Cancel Notifications
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func cancelNotifications(for identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        
        if identifier.contains("site-change") {
            // Navigate to site change screen
        } else if identifier.contains("critical-glucose") {
            // Show emergency actions
        }
        
        completionHandler()
    }
}
