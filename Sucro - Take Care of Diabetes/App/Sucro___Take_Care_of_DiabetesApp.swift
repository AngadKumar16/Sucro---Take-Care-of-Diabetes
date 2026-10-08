//
//  Sucro___Take_Care_of_DiabetesApp.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI
import CoreData

@main
struct SucroApp: App {
    @State private var persistence = PersistenceController.shared
    @State private var settings = SettingsStore.shared
    @State private var healthImporter = HealthGlucoseImporter.shared
    @Environment(\.scenePhase) private var scenePhase
    // Shared by the Monitor tab and the full-screen Monitor opened from Home.
    @State private var monitorViewModel: MonitorViewModel

    private static let isUITesting = ProcessInfo.processInfo.arguments.contains("-uiTesting")
    /// Apple Health stays off in UI tests unless a test turns it on.
    private static let usesHealth = !isUITesting || ProcessInfo.processInfo.arguments.contains("-healthImport")

    init() {
        _monitorViewModel = State(
            initialValue: MonitorViewModel(context: PersistenceController.shared.container.viewContext)
        )

        // UI tests skip the safety notice unless a test asks to see it.
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-resetDisclaimer") {
            SettingsStore.shared.acceptedDisclaimerVersion = 0
        } else if Self.isUITesting {
            SettingsStore.shared.acceptedDisclaimerVersion = SettingsStore.currentDisclaimerVersion
        }

        // UI tests that need a known starting point wipe the store first.
        if arguments.contains("-resetData"), PersistenceController.shared.loadError == nil {
            _ = DataService.shared.clearAllData(context: PersistenceController.shared.container.viewContext)
            AlertService.shared.reset()
            SettingsStore.shared.glucoseUnit = "mg/dL"
        }

        // Registered here rather than in a view so that when HealthKit wakes
        // the app in the background for new glucose, the observer exists.
        let persistence = PersistenceController.shared
        if Self.usesHealth, persistence.loadError == nil {
            HealthGlucoseImporter.shared.start(container: persistence.container)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environment(persistence)
                .environment(monitorViewModel)
                .environment(settings)
                .environment(healthImporter)
                .preferredColorScheme(settings.preferredColorScheme)
                .task {
                    // Run a daily backup if the user has Auto Backup enabled.
                    if persistence.loadError == nil {
                        BackupService.shared.performBackupIfNeeded(context: persistence.container.viewContext)
                    }

                    // Permission prompts are skipped during UI tests so system
                    // sheets don't cover the app.
                    if Self.usesHealth {
                        await HealthKitManager.shared.requestAuthorization()
                        if persistence.loadError == nil {
                            // No-op if init already started it; covers a store
                            // that only opened after Try Again.
                            healthImporter.start(container: persistence.container)
                            await healthImporter.refresh()
                        }
                    }
                    if !Self.isUITesting {
                        await NotificationService.shared.requestAuthorizationIfNeeded()
                    }
                }
                // Catch up on readings that arrived while the app was away,
                // in case background delivery didn't wake it.
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active, Self.usesHealth {
                        Task { await healthImporter.refresh() }
                    }
                }
        }
    }
}
