//
//  GlucoseHeroView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct GlucoseHeroView: View {
    let glucoseReading: GlucoseReading?
    let insulinOnBoard: Double
    let batteryLevel: Double?
    let lastSyncTime: Date?
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Critical Alert Banner (if needed)
            if let reading = glucoseReading, isCriticalGlucose(reading.value) {
                CriticalAlertBanner(glucoseValue: reading.value, onTap: onTap)
            }
            
            // Main Glucose Tile
            Button(action: onTap) {
                VStack(spacing: 12) {
                    // Large glucose reading with trend
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        if let reading = glucoseReading {
                            Text("\(Int(reading.value))")
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundColor(glucoseColor(reading.value))
                            
                            if let trend = reading.trend {
                                Text(trendArrow(for: trend))
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(glucoseColor(reading.value))
                            }
                            
                            if let unit = reading.unit {
                                Text(unit)
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("--")
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Timestamp
                    if let reading = glucoseReading, let timestamp = reading.timestamp {
                        Text("Now • \(timestamp, formatter: timeFormatter)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Secondary info line
                    HStack(spacing: 16) {
                        // IOB
                        HStack(spacing: 4) {
                            Image(systemName: "syringe")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", insulinOnBoard))U")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Battery Status
                        if let battery = batteryLevel {
                            HStack(spacing: 4) {
                                Image(systemName: batteryIcon(for: battery))
                                    .font(.caption)
                                    .foregroundColor(batteryColor(for: battery))
                                Text("\(Int(battery * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Last Sync
                        if let syncTime = lastSyncTime {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(syncTime, formatter: relativeTimeFormatter)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(glucoseReading == nil)
        }
    }
    
    private func isCriticalGlucose(_ value: Double) -> Bool {
        return value < 70 || value > 250
    }
    
    private func glucoseColor(_ value: Double) -> Color {
        switch value {
        case 70...180:
            return .green
        case 50..<70:
            return .orange
        case 180..<250:
            return .orange
        default:
            return .red
        }
    }
    
    private func trendArrow(for trend: String) -> String {
        switch trend.lowercased() {
        case "up", "rising", "doubleup":
            return "↑"
        case "down", "falling", "doubledown":
            return "↓"
        case "flat", "stable", "notchanging":
            return "→"
        default:
            return "→"
        }
    }
    
    private func batteryIcon(for level: Double) -> String {
        if level > 0.6 { return "battery.100" }
        if level > 0.3 { return "battery.50" }
        return "battery.25"
    }
    
    private func batteryColor(for level: Double) -> Color {
        if level > 0.3 { return .secondary }
        return .orange
    }
}

// Formatters
private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

private let relativeTimeFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter
}()

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let sampleReading = GlucoseReading(context: context)
    sampleReading.value = 104
    sampleReading.unit = "mg/dL"
    sampleReading.timestamp = Date()
    sampleReading.trend = "up"
    
    return VStack(spacing: 20) {
        GlucoseHeroView(
            glucoseReading: nil,
            insulinOnBoard: 2.5,
            batteryLevel: 0.8,
            lastSyncTime: Date().addingTimeInterval(-300),
            onTap: {}
        )
        
        GlucoseHeroView(
            glucoseReading: sampleReading,
            insulinOnBoard: 2.5,
            batteryLevel: 0.8,
            lastSyncTime: Date().addingTimeInterval(-300),
            onTap: {}
        )
    }
    .padding()
}
