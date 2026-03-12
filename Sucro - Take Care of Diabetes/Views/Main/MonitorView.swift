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
    @EnvironmentObject var viewModel: MonitorViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Selector
                    Picker("Time Range", selection: $viewModel.timeRange) {
                        ForEach(MonitorViewModel.TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: viewModel.timeRange) { _ in
                        viewModel.updateTimeRange(viewModel.timeRange)
                    }
                    
                    // Statistics Cards
                    HStack(spacing: 16) {
                        StatCard(title: "Average", value: "\(Int(viewModel.averageGlucose))", unit: "mg/dL")
                        StatCard(title: "Range", value: "\(Int(viewModel.glucoseRange.min))-\(Int(viewModel.glucoseRange.max))", unit: "mg/dL")
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
                                    AxisValueLabel(format: .dateTime.hour(.defaultAmPM(.short)))
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
                                .overlay(
                                    Text("Chart available on iOS 16+")
                                        .foregroundColor(.secondary)
                                )
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
            .navigationTitle("Monitor")
            .onAppear {
                viewModel.fetchDataForTimeRange()
            }
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
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    MonitorView()
        .environmentObject(MonitorViewModel(context: PersistenceController.preview.container.viewContext))
}
