//
//  AlertService.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//


//
//  AlertService.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import Foundation

class AlertService {
    static let shared = AlertService()
    
    private init() {}
    
    func checkForCriticalAlerts(
        latestReading: GlucoseReading?,
        isConnected: Bool,
        lastSiteChange: SiteChange?
    ) -> AlertType? {
        
        // Check glucose levels
        if let latest = latestReading {
            if latest.value < 70 {
                NotificationService.shared.scheduleCriticalGlucoseAlert(value: latest.value, isLow: true)
                return .lowGlucose(latest.value)
            }
            
            if latest.value > 250 {
                NotificationService.shared.scheduleCriticalGlucoseAlert(value: latest.value, isLow: false)
                return .highGlucose(latest.value)
            }
        }
        
        // Check device connection
        if !isConnected {
            return .deviceOffline
        }
        
        // Check site change overdue
        if let lastChange = lastSiteChange,
           let daysSince = Calendar.current.dateComponents([.day], from: lastChange.timestamp ?? Date(), to: Date()).day {
            if daysSince >= 3 {
                return .siteChangeOverdue(daysSince)
            }
        }
        
        return nil
    }
    
    func handleAlertAction(_ alert: AlertType) -> AlertAction {
        switch alert {
        case .lowGlucose:
            return .showAddCarb
        case .highGlucose:
            return .showKetoneInfo
        case .deviceOffline:
            return .showDeviceTroubleshooting
        case .siteChangeOverdue:
            return .showSiteChange
        }
    }
}

enum AlertAction {
    case showAddCarb
    case showKetoneInfo
    case showDeviceTroubleshooting
    case showSiteChange
}