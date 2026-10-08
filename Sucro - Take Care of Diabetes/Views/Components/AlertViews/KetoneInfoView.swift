//
//  KetoneInfoView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//


//
//  KetoneInfoView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import SwiftUI

struct KetoneInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsStore.self) private var settings
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AlertCard(
                        icon: "exclamationmark.triangle.fill",
                        color: .orange,
                        title: "High Glucose",
                        message: "High glucose can lead to ketones, especially if it stays high or you feel unwell. Check them now."
                    )
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("When to Check Ketones")
                            .font(.headline)
                        
                        KetoneGuidanceRow(
                            condition: "Glucose over \(settings.formattedGlucose(min(250, settings.urgentHigh)))",
                            action: "Check blood ketones immediately"
                        )
                        KetoneGuidanceRow(
                            condition: "Glucose over \(settings.formattedGlucose(settings.targetHigh)) for 2+ hours",
                            action: "Check urine ketones"
                        )
                        KetoneGuidanceRow(
                            condition: "Feeling nauseous or ill",
                            action: "Check ketones, even if glucose looks normal"
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(.rect(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ketone Levels")
                            .font(.headline)
                        
                        KetoneLevelIndicator(level: .negative, description: "Negative: Keep monitoring as usual")
                        KetoneLevelIndicator(level: .trace, description: "Trace: Drink water and recheck often")
                        KetoneLevelIndicator(level: .moderate, description: "Moderate: Call your care team")
                        KetoneLevelIndicator(level: .large, description: "Large: Get medical care right away")
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("Ketone Guidance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct AlertCard: View {
    let icon: String
    let color: Color
    let title: String
    let message: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(.rect(cornerRadius: 12))
    }
}

struct KetoneGuidanceRow: View {
    let condition: String
    let action: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.blue)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(condition)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(action)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

enum KetoneLevel {
    case negative, trace, moderate, large
    
    var color: Color {
        switch self {
        case .negative: return .green
        case .trace: return .yellow
        case .moderate: return .orange
        case .large: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .negative: return "checkmark.circle.fill"
        case .trace: return "drop.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .large: return "exclamationmark.octagon.fill"
        }
    }
}

struct KetoneLevelIndicator: View {
    let level: KetoneLevel
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: level.icon)
                .foregroundStyle(level.color)
            
            Text(description)
                .font(.subheadline)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}