//
//  InsightsView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI

struct InsightsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // AI Insights Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI-Powered Insights")
                            .font(.headline)
                        
                        InsightCard(
                            title: "Trend Analysis",
                            description: "Your average glucose has decreased by 8% over the past week",
                            type: .positive
                        )
                        
                        InsightCard(
                            title: "Pattern Detection",
                            description: "Higher glucose readings observed after breakfast meals",
                            type: .warning
                        )
                        
                        InsightCard(
                            title: "Recommendation",
                            description: "Consider reducing morning carb intake by 10-15g",
                            type: .info
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Weekly Patterns
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weekly Patterns")
                            .font(.headline)
                        
                        PatternCard(
                            dayOfWeek: "Monday",
                            avgGlucose: 145,
                            trend: .stable
                        )
                        
                        PatternCard(
                            dayOfWeek: "Tuesday",
                            avgGlucose: 132,
                            trend: .improving
                        )
                        
                        PatternCard(
                            dayOfWeek: "Wednesday",
                            avgGlucose: 158,
                            trend: .worsening
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Insights")
        }
    }
}

struct InsightCard: View {
    let title: String
    let description: String
    let type: InsightType
    
    enum InsightType {
        case positive, warning, info
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .warning: return .orange
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .positive: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct PatternCard: View {
    let dayOfWeek: String
    let avgGlucose: Int
    let trend: TrendType
    
    enum TrendType {
        case improving, worsening, stable
        
        var icon: String {
            switch self {
            case .improving: return "arrow.down.right"
            case .worsening: return "arrow.up.right"
            case .stable: return "arrow.right"
            }
        }
        
        var color: Color {
            switch self {
            case .improving: return .green
            case .worsening: return .red
            case .stable: return .gray
            }
        }
    }
    
    var body: some View {
        HStack {
            Text(dayOfWeek)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(avgGlucose) mg/dL")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Image(systemName: trend.icon)
                .foregroundColor(trend.color)
                .font(.caption)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    InsightsView()
}
