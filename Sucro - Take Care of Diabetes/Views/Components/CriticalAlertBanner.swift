//
//  CriticalAlertBanner.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import SwiftUI

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
        
        CriticalAlertBanner(glucoseValue: 65) {}
    }
    .padding()
}
