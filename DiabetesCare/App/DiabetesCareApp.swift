//
//  DiabetesCareApp.swift
//  DiabetesCare
//

import SwiftUI
import CoreData

@main
struct DiabetesCareApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var persistence = PersistenceController.shared
    @State private var settings = SettingsStore.shared
    @State private var healthImporter = HealthGlucoseImporter.shared
    @State private var parentLock = ParentLock.shared
    @State private var parentGate = ParentGate()
    @State private var family = FamilyService.shared
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

        // UI tests start as an adult unless a test sets up a stage:
        // `-stage kid` or `-stage teen` (grown-up passcode 1234), or
        // `-resetSetup` to see the setup screen.
        if Self.isUITesting {
            let settings = SettingsStore.shared
            settings.appRole = .selfCare
            settings.completedSkills = []
            settings.familySharingEnabled = false
            if arguments.contains("-resetSetup") {
                settings.careStage = nil
                ParentLock.shared.removePasscode()
            } else if let index = arguments.firstIndex(of: "-stage"), index + 1 < arguments.count,
                      let stage = CareStage(rawValue: arguments[index + 1]) {
                settings.careStage = stage
                ParentLock.shared.setPasscode("1234")
                ParentLock.shared.lock()
            } else {
                settings.careStage = .adult
                ParentLock.shared.removePasscode()
            }
        }

        // UI tests that need a known starting point wipe the store first.
        if arguments.contains("-resetData"), PersistenceController.shared.loadError == nil {
            _ = DataService.shared.clearAllData(context: PersistenceController.shared.container.viewContext)
            AlertService.shared.reset()
            SettingsStore.shared.glucoseUnit = "mg/dL"
            // A test that failed midway can leave its thresholds behind.
            let standard = GlucoseThresholds.standard
            SettingsStore.shared.urgentLow = standard.urgentLow
            SettingsStore.shared.targetLow = standard.targetLow
            SettingsStore.shared.targetHigh = standard.targetHigh
            SettingsStore.shared.urgentHigh = standard.urgentHigh
        }

        #if DEBUG
        if arguments.contains("-demoData"), PersistenceController.shared.loadError == nil {
            DemoData.install(context: PersistenceController.shared.container.viewContext)
        }
        #endif

        // Registered here rather than in a view so that when HealthKit wakes
        // the app in the background for new glucose, the observer exists.
        let persistence = PersistenceController.shared
        if Self.usesHealth, persistence.loadError == nil {
            HealthGlucoseImporter.shared.start(container: persistence.container)
        }
        if persistence.loadError == nil {
            FamilyService.shared.start(container: persistence.container)
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
                .environment(parentLock)
                .environment(parentGate)
                .environment(family)
                .preferredColorScheme(settings.preferredColorScheme)
                .task {
                    // Run a daily backup if the user has Auto Backup enabled.
                    if persistence.loadError == nil {
                        await BackupService.shared.performBackupIfNeeded(container: persistence.container)
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
                    if phase == .active, persistence.loadError == nil {
                        SkillProgress.refresh(context: persistence.container.viewContext, settings: settings)
                        family.schedulePublish(after: .zero)
                        if !family.followed.isEmpty {
                            Task { await family.refreshFollowed() }
                        }
                    }
                    // A grown-up's unlock doesn't outlive leaving the app.
                    if phase == .background { parentLock.lock() }
                }
        }
    }
}
