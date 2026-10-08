//
//  DevicesView.swift
//  Sucro - Take Care of Diabetes
//
//  Where the app's data comes from and goes. Glucose arrives through Apple
//  Health, which CGM apps such as Dexcom and Libre write to; there's no
//  direct device connection, and the screen says so.
//

import CoreData
import SwiftUI

struct DevicesView: View {
    @Environment(\.openURL) private var openURL
    @Environment(SettingsStore.self) private var settings
    @Environment(HealthGlucoseImporter.self) private var importer
    @State private var savingToHealth = false
    @State private var needsPermission = false

    /// Newest reading imported from Apple Health.
    @FetchRequest(fetchRequest: DevicesView.latestHealthReading)
    private var latestHealthReadings: FetchedResults<GlucoseReading>

    private let health = HealthKitManager.shared

    var body: some View {
        List {
            if health.isHealthDataAvailable {
                glucoseSection
                savingSection
            } else {
                Section("Apple Health") {
                    Text("Apple Health isn't available on this device.")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Label("No direct CGM or pump connection", systemImage: "sensor")
                    .foregroundStyle(.secondary)
            } footer: {
                Text("\(AppInfo.name) doesn't connect to devices over Bluetooth. Readings arrive through Apple Health, or you can log them yourself.")
            }
        }
        .navigationTitle("Devices")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await importer.sync() }
        .task { await refreshPermissions() }
        .sensoryFeedback(.success, trigger: importer.lastChange)
    }

    // MARK: - Glucose from Apple Health

    private var glucoseSection: some View {
        Section {
            // Re-render each minute so the age and status stay current.
            TimelineView(.periodic(from: .now, by: 60)) { context in
                let status = HealthGlucoseStatus(latest: latestHealthReadings.first?.timestamp, now: context.date)
                statusRow(status)
                    .animation(.smooth, value: status)
            }

            if let latest = latestHealthReadings.first, let date = latest.timestamp {
                LabeledContent("Last Reading") {
                    Text(settings.formattedGlucose(latest.value))
                        .foregroundStyle(settings.zone(for: latest.value).color)
                        .contentTransition(.numericText(value: latest.value))
                        .animation(.snappy, value: latest.value)
                }
                LabeledContent("Recorded", value: date.formatted(date: .abbreviated, time: .shortened))
                if let source = importer.latestSourceName {
                    LabeledContent("From", value: source)
                }
            }

            if needsPermission {
                Button("Connect Apple Health", systemImage: "heart.text.square") {
                    Task {
                        await health.requestAuthorization()
                        await refreshPermissions()
                        await importer.refresh()
                    }
                }
            } else {
                Button {
                    Task { await importer.sync() }
                } label: {
                    HStack {
                        Label("Check Now", systemImage: "arrow.clockwise")
                        Spacer()
                        if importer.isSyncing {
                            ProgressView()
                        }
                    }
                }
                .disabled(importer.isSyncing || !importer.isRunning)
            }
        } header: {
            Text("Glucose from Apple Health")
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                if let error = importer.lastError {
                    Text("Couldn't read from Apple Health: \(error)")
                        .foregroundStyle(.red)
                }
                Text("To see CGM readings here, turn on Apple Health sharing in your CGM app, then allow \(AppInfo.name) to read Blood Glucose in Settings › Apps › Health › Data Access & Devices. New readings arrive in the background.")
            }
        }
    }

    private func statusRow(_ status: HealthGlucoseStatus) -> some View {
        LabeledContent {
            Text(status.detail)
                .contentTransition(.numericText())
        } label: {
            Label {
                Text(status.title)
            } icon: {
                Image(systemName: status.symbol)
                    .foregroundStyle(status.color)
                    .symbolEffect(.pulse, isActive: status.isReceiving)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Saving to Apple Health

    private var savingSection: some View {
        Section {
            LabeledContent("Saving to Health", value: savingToHealth ? "On" : "Off")
            Button("Open Health", systemImage: "heart.fill") {
                if let url = URL(string: "x-apple-health://") {
                    openURL(url)
                }
            }
        } header: {
            Text("What You Log")
        } footer: {
            Text(savingToHealth
                 ? "Glucose, carbs, insulin and workouts you log here are also saved to Apple Health."
                 : "To save what you log to Apple Health, open Settings › Apps › Health › Data Access & Devices › \(AppInfo.name) and turn the categories on.")
        }
    }

    private func refreshPermissions() async {
        health.checkAuthorizationStatus()
        savingToHealth = health.isAuthorized
        needsPermission = await health.needsAuthorizationRequest()
    }

    private static var latestHealthReading: NSFetchRequest<GlucoseReading> {
        let request = GlucoseReading.fetchRequest()
        request.predicate = NSPredicate(format: "source == %@", GlucoseSource.health.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReading.timestamp, ascending: false)]
        request.fetchLimit = 1
        return request
    }
}

#Preview {
    NavigationStack {
        DevicesView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    .environment(SettingsStore())
    .environment(HealthGlucoseImporter())
}
