//
//  NotificationService.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation
import UserNotifications

// MARK: - Notification Names
extension Notification.Name {
    static let notificationAuthorizationStatusChanged = Notification.Name("notificationAuthorizationStatusChanged")
    static let criticalGlucoseAlertReceived = Notification.Name("criticalGlucoseAlertReceived")
    static let deviceOfflineAlertReceived = Notification.Name("deviceOfflineAlertReceived")
}

class NotificationService: NSObject {
    static let shared = NotificationService()
    
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined {
        didSet {
            NotificationCenter.default.post(
                name: .notificationAuthorizationStatusChanged,
                object: nil,
                userInfo: ["status": authorizationStatus]
            )
        }
    }
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification authorization error: \(error.localizedDescription)")
                }
                self?.authorizationStatus = granted ? .authorized : .denied
                completion?(granted)
            }
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    // MARK: - Schedule Notifications
    
    func scheduleSiteChangeReminder(days: Int, completion: ((Error?) -> Void)? = nil) {
        // Validate: max 30 days for timeInterval trigger
        let validDays = min(days, 30)
        
        let content = UNMutableNotificationContent()
        content.title = "Site Change Due"
        content.body = "It's been \(days) days since your last infusion site change."
        content.sound = .default
        content.categoryIdentifier = "SITE_CHANGE"
        
        let timeInterval = TimeInterval(validDays * 24 * 3600)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        
        let identifier = "site-change-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to schedule site change reminder: \(error.localizedDescription)")
                }
                completion?(error)
            }
        }
    }
    
    func scheduleCriticalGlucoseAlert(value: Double, isLow: Bool) {
        let content = UNMutableNotificationContent()
        content.title = isLow ? "LOW GLUCOSE" : "HIGH GLUCOSE"
        content.body = isLow ?
            "Glucose is \(Int(value)) mg/dL. Treat with 15g fast carbs." :
            "Glucose is \(Int(value)) mg/dL. Check for ketones."
        
        // Use appropriate sound based on iOS version
        if #available(iOS 15.0, *) {
            content.sound = .defaultCritical
            content.interruptionLevel = .critical
        } else {
            content.sound = .default
        }
        
        let identifier = "critical-glucose-\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil  // Immediate
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule critical glucose alert: \(error.localizedDescription)")
            } else {
                NotificationCenter.default.post(
                    name: .criticalGlucoseAlertReceived,
                    object: nil,
                    userInfo: ["value": value, "isLow": isLow]
                )
            }
        }
    }
    
    func scheduleDeviceOfflineAlert(deviceName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Device Offline"
        content.body = "\(deviceName) has not synced recently. Check connection."
        content.sound = .default
        
        let identifier = "device-offline-\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil  // Immediate
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule device offline alert: \(error.localizedDescription)")
            } else {
                NotificationCenter.default.post(
                    name: .deviceOfflineAlertReceived,
                    object: nil,
                    userInfo: ["deviceName": deviceName]
                )
            }
        }
    }
    
    // MARK: - Cancel Notifications
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func cancelNotifications(for identifierPrefix: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let matchingIds = requests
                .filter { $0.identifier.hasPrefix(identifierPrefix) }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: matchingIds)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge, .list])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        let actionIdentifier = response.actionIdentifier
        
        // Handle different notification types
        if identifier.contains("site-change") {
            NotificationCenter.default.post(
                name: Notification.Name("navigateToSiteChange"),
                object: nil
            )
        } else if identifier.contains("critical-glucose") {
            NotificationCenter.default.post(
                name: Notification.Name("showEmergencyActions"),
                object: nil
            )
        } else if identifier.contains("device-offline") {
            NotificationCenter.default.post(
                name: Notification.Name("showDeviceTroubleshooting"),
                object: nil
            )
        }
        
        completionHandler()
    }
}
