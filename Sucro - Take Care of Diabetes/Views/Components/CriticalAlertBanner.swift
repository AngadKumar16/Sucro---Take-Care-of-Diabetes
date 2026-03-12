//
//  CriticalAlertBanner.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import SwiftUI

enum AlertType {
    case lowGlucose(Double)
    case highGlucose(Double)
    case deviceOffline
    case siteChangeOverdue(Int)
    
    var title: String {
        switch self {
        case .lowGlucose:
            return "LOW GLUCOSE"
        case .highGlucose:
            return "HIGH GLUCOSE"
        case .deviceOffline:
            return "DEVICE OFFLINE"
        case .siteChangeOverdue:
            return "SITE CHANGE DUE"
        }
    }
    
    var message: String {
        switch self {
        case .lowGlucose(let value):
            return "\(Int(value)) mg/dL - Treat immediately"
        case .highGlucose(let value):
            return "\(Int(value)) mg/dL - Check for ketones"
        case .deviceOffline:
            return "CGM sensor needs replacement"
        case .siteChangeOverdue(let days):
            return "\(days) days since last change"
        }
    }
    
    var color: Color {
        switch self {
        case .lowGlucose:
            return .red
        case .highGlucose:
            return .orange
        case .deviceOffline:
            return .purple
        case .siteChangeOverdue:
            return .yellow
        }
    }
    
    var icon: String {
        switch self {
        case .lowGlucose:
            return "exclamationmark.triangle.fill"
        case .highGlucose:
            return "exclamationmark.circle.fill"
        case .deviceOffline:
            return "wifi.slash"
        case .siteChangeOverdue:
            return "bandage.fill"
        }
    }
}

struct CriticalAlertBanner: View {
    let alert: AlertType?
    let onDismiss: () -> Void
    let onAction: () -> Void
    
    var body: some View {
        if let alert = alert {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: alert.icon)
                        .font(.title2)
                        .foregroundColor(alert.color)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(alert.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(alert.color)
                        
                        Text(alert.message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: onAction) {
                    HStack {
                        Image(systemName: actionIcon(for: alert))
                        Text(actionText(for: alert))
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(alert.color)
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(alert.color, lineWidth: 2)
            )
            .cornerRadius(12)
            .shadow(color: alert.color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
    
    private func actionIcon(for alert: AlertType) -> String {
        switch alert {
        case .lowGlucose:
            return "cross.fill"
        case .highGlucose:
            return "drop.fill"
        case .deviceOffline:
            return "arrow.clockwise"
        case .siteChangeOverdue:
            return "arrow.triangle.2.circlepath"
        }
    }
    
    private func actionText(for alert: AlertType) -> String {
        switch alert {
        case .lowGlucose:
            return "Treat Now"
        case .highGlucose:
            return "Check Ketones"
        case .deviceOffline:
            return "Replace Sensor"
        case .siteChangeOverdue:
            return "Change Site"
        }
    }
}

extension CriticalAlertBanner {
    init(glucoseValue: Double, onTap: @escaping () -> Void) {
        self.init(
            alert: glucoseValue < 70 ? .lowGlucose(glucoseValue) : .highGlucose(glucoseValue),
            onDismiss: {},
            onAction: onTap
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        CriticalAlertBanner(
            alert: .lowGlucose(65),
            onDismiss: {},
            onAction: {}
        )
        
        CriticalAlertBanner(
            alert: .highGlucose(250),
            onDismiss: {},
            onAction: {}
        )
        
        CriticalAlertBanner(
            alert: .siteChangeOverdue(4),
            onDismiss: {},
            onAction: {}
        )
        
        // Test convenience initializer
        CriticalAlertBanner(glucoseValue: 65) {}
    }
    .padding()
}
