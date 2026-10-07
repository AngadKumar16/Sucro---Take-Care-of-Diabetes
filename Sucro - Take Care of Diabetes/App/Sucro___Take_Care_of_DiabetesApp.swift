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
    // Shared by the Monitor tab and the full-screen Monitor opened from Home.
    @State private var monitorViewModel: MonitorViewModel

    private static let isUITesting = ProcessInfo.processInfo.arguments.contains("-uiTesting")

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
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environment(persistence)
                .environment(monitorViewModel)
                .environment(settings)
                .preferredColorScheme(settings.preferredColorScheme)
                .task {
                    // Run a daily backup if the user has Auto Backup enabled.
                    if persistence.loadError == nil {
                        BackupService.shared.performBackupIfNeeded(context: persistence.container.viewContext)
                    }

                    // Permission prompts are skipped during UI tests so system
                    // sheets don't cover the app.
                    if !Self.isUITesting {
                        await HealthKitManager.shared.requestAuthorization()
                        await NotificationService.shared.requestAuthorizationIfNeeded()
                    }
                }
        }
    }
}
