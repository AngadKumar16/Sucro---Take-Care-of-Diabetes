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
    @Environment(SettingsStore.self) private var settings

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
        ScrollView {
            VStack(spacing: 20) {
                profileSection
                glucoseSection
                InsulinSettingsSection()
                notificationsSection
                dataManagementSection
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Settings")
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

    // MARK: - Sections

    private let diabetesTypes = ["Type 1 Diabetes", "Type 2 Diabetes", "Gestational", "Prediabetes", "Other"]

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profile")
                .font(.headline)

            HStack(spacing: 16) {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Text(settings.userInitials)
                            .font(.title2)
                            .bold()
                            .foregroundStyle(.blue)
                    }

                VStack(alignment: .leading, spacing: 8) {
                    TextField("Your name", text: Bindable(settings).userName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .textInputAutocapitalization(.words)

                    Picker("Diabetes Type", selection: Bindable(settings).diabetesType) {
                        ForEach(diabetesTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var glucoseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Glucose Settings")
                .font(.headline)

            VStack(spacing: 8) {
                SettingsRow(title: "Unit", value: settings.glucoseUnit) {
                    Picker("Unit", selection: Bindable(settings).glucoseUnit) {
                        Text("mg/dL").tag("mg/dL")
                        Text("mmol/L").tag("mmol/L")
                    }
                    .pickerStyle(.menu)
                }

                ThresholdRow(title: "Urgent Low", value: Bindable(settings).urgentLow, bounds: settings.urgentLowBounds)
                ThresholdRow(title: "Low", value: Bindable(settings).targetLow, bounds: settings.targetLowBounds)
                ThresholdRow(title: "High", value: Bindable(settings).targetHigh, bounds: settings.targetHighBounds)
                ThresholdRow(title: "Urgent High", value: Bindable(settings).urgentHigh, bounds: settings.urgentHighBounds)
            }

            Text("Readings between Low and High count as in range. You get an alert below Low and above Urgent High.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notifications & Appearance")
                .font(.headline)

            VStack(spacing: 8) {
                ToggleRow(title: "Enable Notifications", isOn: Bindable(settings).notificationsEnabled)
                    .onChange(of: settings.notificationsEnabled) { _, enabled in
                        notificationsToggled(enabled)
                    }
                ToggleRow(title: "Dark Mode", isOn: Bindable(settings).darkModeEnabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Management")
                .font(.headline)

            VStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    ToggleRow(title: "Auto Backup", isOn: Bindable(settings).autoBackupEnabled)
                        .onChange(of: settings.autoBackupEnabled) { _, enabled in
                            if enabled { runBackup() }
                        }

                    if settings.autoBackupEnabled {
                        Text(backupStatusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

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
                    .foregroundStyle(.primary)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(.rect(cornerRadius: 8))
                }
                .disabled(isExporting)

                Button(action: { showClearConfirm = true }) {
                    HStack {
                        Text("Clear All Data")
                            .foregroundStyle(.red)
                        Spacer()
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(.rect(cornerRadius: 8))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(.rect(cornerRadius: 12))
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
            statusMessage = "No glucose readings to export yet."
            showStatusAlert = true
            return
        }

        defer { isExporting = false }
        do {
            exportURL = try exportService.exportToCSV(glucoseReadings: readings)
            showShareSheet = true
        } catch {
            statusMessage = error.localizedDescription
            showStatusAlert = true
        }
    }

    private var backupStatusText: String {
        guard let last = settings.lastBackupDate else {
            return "No backup yet"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Last backup: \(formatter.string(from: last))"
    }

    private func runBackup() {
        // Force a backup now so enabling the toggle has an immediate effect.
        _ = BackupService.shared.performBackup(context: viewContext)
    }

    private func notificationsToggled(_ enabled: Bool) {
        guard enabled else {
            NotificationService.shared.cancelAll()
            return
        }
        ReminderService.shared.refresh(context: viewContext)
        AlertService.shared.evaluate(context: viewContext)
        Task { await NotificationService.shared.requestAuthorizationIfNeeded() }
    }

    private func clearAllData() {
        let success = dataService.clearAllData(context: viewContext)
        if success {
            AlertService.shared.reset()
            ReminderService.shared.reset()
            NotificationService.shared.cancelAll()
        }
        statusMessage = success
            ? "All your data has been deleted."
            : "Couldn't delete your data. Please try again."
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
        .environment(SettingsStore())
}
