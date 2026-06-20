//
//  ReportsView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct ReportsView: View {
    @EnvironmentObject var viewModel: ReportsViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Report Type Selector
                    Picker("Report Type", selection: $viewModel.period) {
                        ForEach(ReportsViewModel.Period.allCases, id: \.self) { type in
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
                            StatCard(title: "Avg Glucose", value: viewModel.avgGlucose, unit: viewModel.glucoseUnitLabel)
                            StatCard(title: "Time in Range", value: viewModel.timeInRange, unit: "%")
                            StatCard(title: "Total Insulin", value: viewModel.insulinPerDay, unit: "units/day")
                            StatCard(title: "Avg Carbs", value: viewModel.carbsPerDay, unit: "g/day")
                        }

                        if !viewModel.hasData {
                            Text("No data logged for this period yet.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
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
                            ExportButton(title: "Export as PDF", icon: "doc.fill") {
                                viewModel.exportPDF()
                            }
                            ExportButton(title: "Share with Doctor", icon: "square.and.arrow.up") {
                                viewModel.exportPDF()
                            }
                            ExportButton(title: "Print Report", icon: "printer") {
                                viewModel.printReport()
                            }
                        }

                        if viewModel.isExporting {
                            HStack {
                                ProgressView()
                                Text("Generating report…")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
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
            .onAppear { viewModel.recalculate() }
            .sheet(isPresented: $viewModel.showShareSheet) {
                if let url = viewModel.exportURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Sucro", isPresented: $viewModel.showStatusAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.statusMessage ?? "")
            }
        }
    }
}

struct ExportButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
        .environmentObject(ReportsViewModel(context: PersistenceController.preview.container.viewContext))
}
