//
//  HomeView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Glucose Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Glucose")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if let reading = viewModel.latestGlucoseReading {
                            HStack {
                                Text("\(Int(reading.value))")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(reading.value > 180 ? .red : reading.value < 70 ? .orange : .green)
                                
                                Text(reading.unit)
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let timestamp = reading.timestamp {
                                Text("Last updated: \(timestamp, formatter: timeFormatter)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("No reading available")
                                .font(.title)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Today's Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Summary")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(Int(viewModel.todayInsulinTotal))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Insulin Units")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                                .frame(height: 40)
                            
                            VStack {
                                Text("\(Int(viewModel.todayCarbTotal))g")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Carbs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Recent Readings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Readings")
                            .font(.headline)
                        
                        ForEach(viewModel.recentReadings.prefix(5)) { reading in
                            HStack {
                                Text("\(Int(reading.value)) \(reading.unit)")
                                    .font(.body)
                                Spacer()
                                if let timestamp = reading.timestamp {
                                    Text(timestamp, formatter: timeFormatter)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
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
            .navigationTitle("Sucro")
            .onAppear {
                viewModel.fetchLatestData()
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
    HomeView()
        .environmentObject(HomeViewModel(context: PersistenceController.preview.container.viewContext))
}
