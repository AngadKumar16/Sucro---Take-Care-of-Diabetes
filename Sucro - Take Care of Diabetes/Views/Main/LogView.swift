//
//  LogView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct LogView: View {
    @Environment(LogViewModel.self) private var viewModel
    @Environment(SettingsStore.self) private var settings
    @State private var selectedLogType: LogType = .glucose
    
    enum LogType: String, CaseIterable {
        case glucose = "Glucose"
        case carbs = "Carbs"
        case insulin = "Insulin"
        case activity = "Activity"
    }
    
    var body: some View {
        VStack {
            // Date Picker
            DatePicker("Date", selection: Bindable(viewModel).selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .onChange(of: viewModel.selectedDate) { _, date in
                    viewModel.fetchEntriesForDate(date)
                }
            
            // Log Type Selector
            Picker("Log Type", selection: $selectedLogType) {
                ForEach(LogType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
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
            Button(action: showAddForm) {
                Text("Add \(selectedLogType.rawValue)")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(.rect(cornerRadius: 12))
            }
            .padding()
        }
        .navigationTitle("Log")
        .task {
            viewModel.fetchEntriesForDate(viewModel.selectedDate)
        }
        .sheet(isPresented: Bindable(viewModel).showAddGlucose) {
            AddGlucoseView()
                .environment(viewModel)
        }
        .sheet(isPresented: Bindable(viewModel).showAddCarbs) {
            AddCarbView()
                .environment(viewModel)
        }
        .sheet(isPresented: Bindable(viewModel).showAddInsulin) {
            AddInsulinView()
                .environment(viewModel)
        }
        .sheet(isPresented: Bindable(viewModel).showAddActivity) {
            AddActivityView()
                .environment(viewModel)
        }
    }
    
    private func showAddForm() {
        switch selectedLogType {
        case .glucose: viewModel.showAddGlucose = true
        case .carbs: viewModel.showAddCarbs = true
        case .insulin: viewModel.showAddInsulin = true
        case .activity: viewModel.showAddActivity = true
        }
    }

    private var glucoseLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Glucose Readings")
                .font(.headline)
            
            if viewModel.glucoseReadings.isEmpty {
                Text("No glucose readings for this date")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.glucoseReadings) { reading in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(settings.formattedGlucose(reading.value))
                                .font(.body)
                                .fontWeight(.medium)
                            
                            if let context = reading.context {
                                Text(context)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if let timestamp = reading.timestamp {
                            Text(timestamp, formatter: timeFormatter)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(.rect(cornerRadius: 8))
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
                    .foregroundStyle(.secondary)
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
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if let timestamp = entry.timestamp {
                            Text(timestamp, formatter: timeFormatter)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(.rect(cornerRadius: 8))
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
                    .foregroundStyle(.secondary)
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
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if let timestamp = entry.timestamp {
                            Text(timestamp, formatter: timeFormatter)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(.rect(cornerRadius: 8))
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
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.activityEntries) { entry in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(entry.type ?? "Activity")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Text("\(entry.duration) min")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if let timestamp = entry.timestamp {
                            Text(timestamp, formatter: timeFormatter)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(.rect(cornerRadius: 8))
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
        .environment(LogViewModel(context: PersistenceController.preview.container.viewContext))
        .environment(SettingsStore())
}
