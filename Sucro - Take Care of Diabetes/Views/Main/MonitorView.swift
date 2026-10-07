//
//  MonitorView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData
import Charts

struct MonitorView: View {
    @Environment(MonitorViewModel.self) private var viewModel
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time Range Selector
                Picker("Time Range", selection: Bindable(viewModel).timeRange) {
                    ForEach(MonitorViewModel.TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Statistics Cards
                HStack(spacing: 16) {
                    StatCard(title: "Average", value: settings.glucoseValueString(viewModel.averageGlucose), unit: settings.glucoseUnit)
                    StatCard(title: "Range", value: "\(settings.glucoseValueString(viewModel.glucoseRange.min))-\(settings.glucoseValueString(viewModel.glucoseRange.max))", unit: settings.glucoseUnit)
                }
                
                StatCard(title: "Time in Range", value: "\(Int(viewModel.timeInRange))", unit: "%")
                
                // Glucose Trend Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Glucose Trend")
                        .font(.headline)
                    
                    if #available(iOS 16.0, *) {
                        Chart(viewModel.trendData) { point in
                            LineMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Glucose", point.value)
                            )
                            .foregroundStyle(.blue)
                            .symbol(.circle)
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .automatic) { value in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.hour())
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) {
                                AxisGridLine()
                                AxisValueLabel()
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .overlay {
                                Text("Charts need iOS 16 or later.")
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(.rect(cornerRadius: 12))
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Monitor")
        .onAppear {
            viewModel.fetchDataForTimeRange()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .bold()
                
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(.rect(cornerRadius: 12))
    }
}

#Preview {
    MonitorView()
        .environment(MonitorViewModel(context: PersistenceController.preview.container.viewContext))
        .environment(SettingsStore())
}
