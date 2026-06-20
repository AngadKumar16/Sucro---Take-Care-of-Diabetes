//
//  SettingsView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var settings: SettingsStore

    // Local mirror for the target-range text field; committed on change.
    @State private var targetRangeText: String = ""

    // Export / clear state
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var showClearConfirm = false
    @State private var statusMessage: String?
    @State private var showStatusAlert = false
    @State private var isExporting = false

    private let dataService = DataService.shared
    private let exportService = ExportService.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    profileSection
                    glucoseSection
                    notificationsSection
                    dataManagementSection
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Settings")
            .onAppear { targetRangeText = settings.targetRangeString }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Clear All Data?", isPresented: $showClearConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) { clearAllData() }
            } message: {
                Text("This permanently deletes all glucose readings, insulin, carbs, activity, and site changes. This cannot be undone.")
            }
            .alert("Sucro", isPresented: $showStatusAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(statusMessage ?? "")
            }
        }
    }

    // MARK: - Sections

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profile")
                .font(.headline)

            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text("AK")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Angad Kumar")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Type 1 Diabetes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var glucoseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Glucose Settings")
                .font(.headline)

            VStack(spacing: 8) {
                SettingsRow(title: "Unit", value: settings.glucoseUnit) {
                    Picker("Unit", selection: $settings.glucoseUnit) {
                        Text("mg/dL").tag("mg/dL")
                        Text("mmol/L").tag("mmol/L")
                    }
                    .pickerStyle(.menu)
                }

                SettingsRow(title: "Target Range", value: settings.targetRangeString) {
                    TextField("70-180", text: $targetRangeText)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                        .onSubmit { settings.targetRangeString = targetRangeText }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notifications & Appearance")
                .font(.headline)

            VStack(spacing: 8) {
                ToggleRow(title: "Enable Notifications", isOn: $settings.notificationsEnabled)
                ToggleRow(title: "Dark Mode", isOn: $settings.darkModeEnabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Management")
                .font(.headline)

            VStack(spacing: 8) {
                ToggleRow(title: "Auto Backup", isOn: $settings.autoBackupEnabled)

                Button(action: exportData) {
                    HStack {
                        Text(isExporting ? "Exporting…" : "Export Data")
                        Spacer()
                        if isExporting {
                            ProgressView()
                        } else {
                            Image(systemName: "square.and.arrow.up")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
                .disabled(isExporting)

                Button(action: { showClearConfirm = true }) {
                    HStack {
                        Text("Clear All Data")
                            .foregroundColor(.red)
                        Spacer()
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func exportData() {
        isExporting = true
        let calendar = Calendar.current
        let end = Date()
        let start = calendar.date(byAdding: .day, value: -90, to: end) ?? end
        let range = DateInterval(start: start, end: end)

        let readings = dataService.fetchGlucoseReadings(context: viewContext, in: range)

        guard !readings.isEmpty else {
            isExporting = false
            statusMessage = "No glucose data available to export yet."
            showStatusAlert = true
            return
        }

        exportService.exportToCSV(glucoseReadings: readings) { result in
            DispatchQueue.main.async {
                isExporting = false
                switch result {
                case .success(let url):
                    exportURL = url
                    showShareSheet = true
                case .failure(let error):
                    statusMessage = error.localizedDescription
                    showStatusAlert = true
                }
            }
        }
    }

    private func clearAllData() {
        let success = dataService.clearAllData(context: viewContext)
        statusMessage = success
            ? "All data has been cleared."
            : "Something went wrong while clearing data."
        showStatusAlert = true
    }
}

struct SettingsRow<Content: View>: View {
    let title: String
    let value: String
    let content: Content

    init(title: String, value: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.value = value
        self.content = content()
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)

            Spacer()

            content
        }
        .padding(.vertical, 8)
    }
}

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)

            Spacer()

            Toggle("", isOn: $isOn)
                .accessibilityIdentifier(title)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(SettingsStore())
}
