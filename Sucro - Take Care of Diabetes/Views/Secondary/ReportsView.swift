//
//  ReportsView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct ReportsView: View {
    @Environment(ReportsViewModel.self) private var viewModel

    var body: some View {
        List {
            Section {
                Picker("Report Period", selection: Bindable(viewModel).period) {
                    ForEach(TimeRange.reports, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            Section {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    StatTile(title: "Average Glucose", value: viewModel.avgGlucose, unit: viewModel.glucoseUnitLabel)
                    StatTile(title: "Time in Range", value: viewModel.timeInRange, unit: "%")
                    StatTile(title: "Insulin", value: viewModel.insulinPerDay, unit: "units per day")
                    StatTile(title: "Carbs", value: viewModel.carbsPerDay, unit: "grams per day")
                }
            } header: {
                Text("Summary Statistics")
            } footer: {
                if !viewModel.hasData {
                    Text("Nothing logged for this period yet.")
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            Section {
                Button(action: viewModel.exportPDF) {
                    HStack {
                        Label("Share PDF Report", systemImage: "square.and.arrow.up")
                        Spacer()
                        if viewModel.isExporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isExporting)
                Button("Print Report", systemImage: "printer", action: viewModel.printReport)
                    .disabled(viewModel.isExporting)
            } header: {
                Text("Export")
            } footer: {
                Text("The report covers glucose, insulin and carbs for the period above. Share it with your care team by Mail, Messages or AirDrop.")
            }

            .listRowBackground(Theme.card)
        }
        .listStyle(.insetGrouped)
        .instrumentBackground()
        .navigationTitle("Reports")
        .onAppear(perform: viewModel.recalculate)
        .sheet(isPresented: Bindable(viewModel).showShareSheet) {
            if let url = viewModel.exportURL {
                ShareSheet(items: [url])
                    .presentationDetents([.medium, .large])
            }
        }
        .alert(viewModel.statusTitle, isPresented: Bindable(viewModel).showStatusAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.statusMessage ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        ReportsView()
    }
    .environment(ReportsViewModel(context: PersistenceController.preview.container.viewContext))
    .environment(SettingsStore())
}
