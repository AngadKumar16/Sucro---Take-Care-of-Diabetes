//
//  LogView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct LogView: View {
    @EnvironmentObject var viewModel: LogViewModel
    @State private var selectedLogType: LogType = .glucose
    
    enum LogType: String, CaseIterable {
        case glucose = "Glucose"
        case carbs = "Carbs"
        case insulin = "Insulin"
        case activity = "Activity"
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Date Picker
                DatePicker("Date", selection: $viewModel.selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    .onChange(of: viewModel.selectedDate) { _ in
                        viewModel.fetchEntriesForDate(viewModel.selectedDate)
                    }
                
                // Log Type Selector
                Picker("Log Type", selection: $selectedLogType) {
                    ForEach(LogType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Content based on selection
                ScrollView {
                    LazyVStack(spacing: 16) {
                        switch selectedLogType {
                        case .glucose:
                            glucoseLogSection
                        case .carbs:
                            carbLogSection
                        case .insulin:
                            insulinLogSection
                        case .activity:
                            activityLogSection
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                // Add Button
                Button(action: {
                    switch selectedLogType {
                    case .glucose:
                        viewModel.showAddGlucose = true
                    case .carbs:
                        viewModel.showAddCarbs = true
                    case .insulin:
                        viewModel.showAddInsulin = true
                    case .activity:
                        viewModel.showAddActivity = true
                    }
                }) {
                    Text("Add \(selectedLogType.rawValue)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Log")
            .sheet(isPresented: $viewModel.showAddGlucose) {
                AddGlucoseView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $viewModel.showAddCarbs) {
                AddCarbView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $viewModel.showAddInsulin) {
                AddInsulinView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $viewModel.showAddActivity) {
                AddActivityView()
                    .environmentObject(viewModel)
            }
        }
    }
    
    private var glucoseLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Glucose Readings")
                .font(.headline)
            
            if viewModel.glucoseReadings.isEmpty {
                Text("No glucose readings for this date")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.glucoseReadings) { reading in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(Int(reading.value)) \(reading.unit)")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            if let context = reading.context {
                                Text(context)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if let timestamp = reading.timestamp {
                            Text(timestamp, formatter: timeFormatter)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private var carbLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Carb Entries")
                .font(.headline)
            
            if viewModel.carbEntries.isEmpty {
                Text("No carb entries for this date")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.carbEntries) { entry in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(Int(entry.grams))g carbs")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            if let mealType = entry.mealType {
                                Text(mealType)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if let timestamp = entry.timestamp {
                            Text(timestamp, formatter: timeFormatter)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private var insulinLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insulin Entries")
                .font(.headline)
            
            if viewModel.insulinEntries.isEmpty {
                Text("No insulin entries for this date")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.insulinEntries) { entry in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(entry.units, specifier: "%.1f") units")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            if let type = entry.type {
                                Text(type)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if let timestamp = entry.timestamp {
                            Text(timestamp, formatter: timeFormatter)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private var activityLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Entries")
                .font(.headline)
            
            if viewModel.activityEntries.isEmpty {
                Text("No activity entries for this date")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.activityEntries) { entry in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(entry.type ?? "Activity")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Text("\(entry.duration) min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if let timestamp = entry.timestamp {
                            Text(timestamp, formatter: timeFormatter)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }
}

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    LogView()
        .environmentObject(LogViewModel(context: PersistenceController.preview.container.viewContext))
}
