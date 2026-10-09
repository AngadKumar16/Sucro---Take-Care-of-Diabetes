//
//  SettingsView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData
import UserNotifications

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(SettingsStore.self) private var settings

    // Export / clear state
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var showClearConfirm = false
    @State private var statusTitle = ""
    @State private var statusMessage: String?
    @State private var showStatusAlert = false
    @State private var isExporting = false
    /// The user turned notifications off for the app in iOS Settings.
    @State private var notificationsDenied = false

    private let dataService = DataService.shared
    private let exportService = ExportService.shared
    private let diabetesTypes = ["Type 1 Diabetes", "Type 2 Diabetes", "Gestational", "Prediabetes", "Other"]

    var body: some View {
        Form {
            profileSection
            glucoseSection
            guidesSection
            InsulinSettingsSection()
            notificationsSection
            appearanceSection
            dataSection
            moreSection
            Section {
                LabeledContent("Version", value: AppInfo.version)
            }
            .listRowBackground(Theme.card)
        }
        .listRowBackground(Theme.card)
        .instrumentBackground()
        .navigationTitle("Settings")
        .helpDestinations()
        .task { await checkNotificationPermission() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await checkNotificationPermission() } }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
                    .presentationDetents([.medium, .large])
            }
        }
        .alert("Clear All Data?", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Everything", role: .destructive) { clearAllData() }
        } message: {
            Text("This permanently deletes all glucose readings, insulin, carbs, activity, and site changes on this phone. This can't be undone. Anything saved to Apple Health stays there, and glucose from Apple Health for the last 30 days is read in again.")
        }
        .alert(statusTitle, isPresented: $showStatusAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(statusMessage ?? "")
        }
    }

    // MARK: - Sections

    private var profileSection: some View {
        Section("Profile") {
            TextField("Your Name", text: Bindable(settings).userName)
                .textInputAutocapitalization(.words)
                .textContentType(.name)
            Picker("Diabetes Type", selection: Bindable(settings).diabetesType) {
                ForEach(diabetesTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
        }
        .listRowBackground(Theme.card)
    }

    private var glucoseSection: some View {
        Section {
            Picker("Unit", selection: Bindable(settings).glucoseUnit) {
                Text("mg/dL").tag("mg/dL")
                Text("mmol/L").tag("mmol/L")
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
            GlucoseRangeBar(thresholds: settings.thresholds)
            ThresholdRow(title: "Urgent High", zone: .urgentHigh, value: Bindable(settings).urgentHigh, bounds: settings.urgentHighBounds)
            ThresholdRow(title: "High", zone: .high, value: Bindable(settings).targetHigh, bounds: settings.targetHighBounds)
            ThresholdRow(title: "Low", zone: .low, value: Bindable(settings).targetLow, bounds: settings.targetLowBounds)
            ThresholdRow(title: "Urgent Low", zone: .urgentLow, value: Bindable(settings).urgentLow, bounds: settings.urgentLowBounds)
            Button("Reset to Common Defaults", systemImage: "arrow.counterclockwise") {
                resetThresholds()
            }
            .disabled(settings.thresholds == .standard)
        } header: {
            Text("Glucose")
        } footer: {
            Text("Readings between Low and High count as in range. You get an alert below Low and above Urgent High.")
        }
        .listRowBackground(Theme.card)
    }

    private var guidesSection: some View {
        Section("Learn About Glucose") {
            GuideCarousel()
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }
        .listRowBackground(Theme.card)
    }

    private var notificationsSection: some View {
        Section {
            Toggle("Notifications", isOn: Bindable(settings).notificationsEnabled)
                .accessibilityIdentifier("Enable Notifications")
                .onChange(of: settings.notificationsEnabled) { _, enabled in
                    notificationsToggled(enabled)
                }
            if notificationsDenied && settings.notificationsEnabled {
                Button("Turn On in iOS Settings", systemImage: "gear") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        openURL(url)
                    }
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            if notificationsDenied && settings.notificationsEnabled {
                Text("Notifications are turned off for \(AppInfo.name) in iOS Settings, so glucose alerts and reminders can't reach you.")
            } else {
                Text("Glucose alerts, site change reminders and post-dose glucose checks.")
            }
        }
        .listRowBackground(Theme.card)
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Appearance", selection: Bindable(settings).appearance) {
                ForEach(Appearance.allCases, id: \.self) { appearance in
                    Text(appearance.displayName).tag(appearance)
                }
            }
            .accessibilityIdentifier("appearancePicker")
        }
        .listRowBackground(Theme.card)
    }

    private var dataSection: some View {
        Section {
            Toggle("Daily Backup", isOn: Bindable(settings).autoBackupEnabled)
                .accessibilityIdentifier("Auto Backup")
                .onChange(of: settings.autoBackupEnabled) { _, enabled in
                    if enabled { runBackup() }
                }
            Button(action: exportData) {
                HStack {
                    Label("Export Glucose (CSV)", systemImage: "square.and.arrow.up")
                    Spacer()
                    if isExporting { ProgressView() }
                }
            }
            .disabled(isExporting)
            .accessibilityIdentifier("Export Data")
            Button("Clear All Data", systemImage: "trash", role: .destructive) {
                showClearConfirm = true
            }
            .foregroundStyle(.red)
        } header: {
            Text("Data")
        } footer: {
            Text(backupFooter)
        }
        .listRowBackground(Theme.card)
    }

    private var moreSection: some View {
        Section {
            NavigationLink(value: HelpDestination.devices) {
                Label("Devices & Apple Health", systemImage: "heart.text.square")
            }
            NavigationLink(value: HelpDestination.help) {
                Label("Help", systemImage: "questionmark.circle")
            }
            NavigationLink(value: HelpDestination.safety) {
                Label("Safety Information", systemImage: "exclamationmark.shield")
            }
        }
        .listRowBackground(Theme.card)
    }

    // MARK: - Actions

    private var backupFooter: String {
        guard settings.autoBackupEnabled else {
            return "Export saves your last 90 days of glucose readings as a spreadsheet."
        }
        let last = settings.lastBackupDate.map { "Last backup \($0.formatted(date: .abbreviated, time: .shortened))." } ?? "No backup yet."
        return "Saves your glucose readings on this phone once a day. \(last) Export saves your last 90 days as a spreadsheet."
    }

    private func resetThresholds() {
        withAnimation(.snappy) {
            let standard = GlucoseThresholds.standard
            settings.targetLow = standard.targetLow
            settings.targetHigh = standard.targetHigh
            settings.urgentLow = standard.urgentLow
            settings.urgentHigh = standard.urgentHigh
        }
    }

    private func checkNotificationPermission() async {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        notificationsDenied = status == .denied
    }

    private func exportData() {
        isExporting = true
        defer { isExporting = false }
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -90, to: end) ?? end
        let readings = dataService.fetchGlucoseReadings(context: viewContext, in: DateInterval(start: start, end: end))
        guard !readings.isEmpty else {
            showStatus("Nothing to Export", "No glucose readings in the last 90 days.")
            return
        }
        do {
            exportURL = try exportService.exportToCSV(glucoseReadings: readings)
            showShareSheet = true
        } catch {
            showStatus("Couldn't Export", error.localizedDescription)
        }
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
        Task {
            await NotificationService.shared.requestAuthorizationIfNeeded()
            await checkNotificationPermission()
        }
    }

    private func clearAllData() {
        let success = dataService.clearAllData(context: viewContext)
        if success {
            AlertService.shared.reset()
            ReminderService.shared.reset()
            HealthGlucoseImporter.shared.resetAnchor()
            Task { await HealthGlucoseImporter.shared.sync() }
            NotificationService.shared.cancelAll()
            showStatus("Data Deleted", "All your data on this phone has been deleted.")
        } else {
            showStatus("Couldn't Delete Data", "Please try again.")
        }
    }

    private func showStatus(_ title: String, _ message: String) {
        statusTitle = title
        statusMessage = message
        showStatusAlert = true
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    .environment(SettingsStore())
}
