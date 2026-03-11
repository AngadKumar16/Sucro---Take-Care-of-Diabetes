//
//  ReportsView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI

struct ReportsView: View {
    @State private var selectedReport: ReportType = .weekly
    
    enum ReportType: String, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case yearly = "Yearly"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Report Type Selector
                    Picker("Report Type", selection: $selectedReport) {
                        ForEach(ReportType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Summary Statistics
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Summary Statistics")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            StatCard(title: "Avg Glucose", value: "142", unit: "mg/dL")
                            StatCard(title: "Time in Range", value: "73", unit: "%")
                            StatCard(title: "Total Insulin", value: "28.5", unit: "units/day")
                            StatCard(title: "Avg Carbs", value: "156", unit: "g/day")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Export Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Export Reports")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            ExportButton(title: "Export as PDF", icon: "doc.fill")
                            ExportButton(title: "Share with Doctor", icon: "square.and.arrow.up")
                            ExportButton(title: "Print Report", icon: "printer")
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
            .navigationTitle("Reports")
        }
    }
}

struct ExportButton: View {
    let title: String
    let icon: String
    
    var body: some View {
        Button(action: {
            // Handle export action
        }) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    ReportsView()
}
