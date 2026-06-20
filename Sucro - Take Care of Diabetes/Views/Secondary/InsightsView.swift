//
//  InsightsView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct InsightsView: View {
    @EnvironmentObject var viewModel: InsightsViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Selector
                    Picker("Time Range", selection: Binding(
                        get: { viewModel.timeRange },
                        set: { viewModel.updateTimeRange($0) }
                    )) {
                        ForEach(InsightsViewModel.TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    // AI Insights Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI-Powered Insights")
                            .font(.headline)

                        if viewModel.generatedInsights.isEmpty {
                            Text("Log data to unlock insights.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(viewModel.generatedInsights) { insight in
                                InsightCard(
                                    title: insight.title,
                                    description: insight.description,
                                    type: insight.type
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Weekly Patterns
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weekly Patterns")
                            .font(.headline)

                        if viewModel.weeklyPatterns.isEmpty {
                            Text("No readings in the past week.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(viewModel.weeklyPatterns) { pattern in
                                PatternCard(
                                    dayOfWeek: pattern.name,
                                    avgGlucose: Int(pattern.average),
                                    trend: PatternCard.TrendType(glucoseTrend: pattern.trend)
                                )
                            }
                        }
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
            .onAppear { viewModel.fetchInsights() }
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

        init(glucoseTrend: GlucoseTrend) {
            switch glucoseTrend {
            case .falling, .fallingFast:
                self = .improving
            case .rising, .risingFast:
                self = .worsening
            case .stable:
                self = .stable
            }
        }

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
        .environmentObject(InsightsViewModel(context: PersistenceController.preview.container.viewContext))
}
