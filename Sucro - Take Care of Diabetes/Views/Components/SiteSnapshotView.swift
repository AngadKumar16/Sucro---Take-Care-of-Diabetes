//
//  SiteSnapshotView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct SiteSnapshotView: View {
    let lastSiteChange: SiteChange?
    let onChangeSite: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Infusion Site")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let siteChange = lastSiteChange {
                HStack(spacing: 16) {
                    // Body Map
                    BodyMapView(
                        selectedLocation: siteChange.location ?? "Abdomen",
                        onTap: { onChangeSite() }
                    )
                    .frame(width: 80, height: 120)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // Site Info
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Site")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(siteChange.location ?? "Unknown")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        // Time Since Change
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Duration")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(timeSinceChange(siteChange.timestamp ?? Date()))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
            } else {
                // Empty State
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("No site recorded")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Mark New Site") {
                        onChangeSite()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private func timeSinceChange(_ timestamp: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: timestamp, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            return "Just now"
        }
    }
}

struct BodyMapView: View {
    let selectedLocation: String
    let onTap: () -> Void
    
    private let bodySites: [String: CGPoint] = [
        "Abdomen": CGPoint(x: 0.5, y: 0.4),
        "Thigh": CGPoint(x: 0.5, y: 0.7),
        "Arm": CGPoint(x: 0.8, y: 0.5),
        "Buttock": CGPoint(x: 0.3, y: 0.6)
    ]
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Simple body outline
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 100)
                
                // Body parts
                VStack(spacing: 4) {
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 20, height: 20)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray4))
                        .frame(width: 40, height: 60)
                }
                
                // Site marker
                if let position = bodySites[selectedLocation] {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .position(
                            x: 60 * position.x,
                            y: 100 * position.y
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1)
                        )
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 20) {
        SiteSnapshotView(
            lastSiteChange: {
                let siteChange = SiteChange()
                siteChange.location = "Abdomen"
                siteChange.timestamp = Date().addingTimeInterval(-86400) // 1 day ago
                return siteChange
            }(),
            onChangeSite: {}
        )
        
        SiteSnapshotView(
            lastSiteChange: nil,
            onChangeSite: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
