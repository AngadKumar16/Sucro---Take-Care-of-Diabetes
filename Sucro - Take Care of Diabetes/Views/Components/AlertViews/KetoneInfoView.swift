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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AlertCard(
                        icon: "exclamationmark.triangle.fill",
                        color: .orange,
                        title: "High Glucose & Rising",
                        message: "Your glucose is above 180 mg/dL and trending upward. Consider checking ketones."
                    )
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("When to Check Ketones")
                            .font(.headline)
                        
                        KetoneGuidanceRow(
                            condition: "Glucose > 250 mg/dL",
                            action: "Check blood ketones immediately"
                        )
                        KetoneGuidanceRow(
                            condition: "Glucose > 180 for 2+ hours",
                            action: "Check urine ketones"
                        )
                        KetoneGuidanceRow(
                            condition: "Feeling nauseous or ill",
                            action: "Check ketones regardless of glucose"
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ketone Levels")
                            .font(.headline)
                        
                        KetoneLevelIndicator(level: .negative, description: "Negative: Continue normal monitoring")
                        KetoneLevelIndicator(level: .trace, description: "Trace: Drink water, monitor closely")
                        KetoneLevelIndicator(level: .moderate, description: "Moderate: Contact healthcare provider")
                        KetoneLevelIndicator(level: .large, description: "Large: Seek immediate medical care")
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
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct KetoneGuidanceRow: View {
    let condition: String
    let action: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.blue)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(condition)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(action)
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                .foregroundColor(level.color)
            
            Text(description)
                .font(.subheadline)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}