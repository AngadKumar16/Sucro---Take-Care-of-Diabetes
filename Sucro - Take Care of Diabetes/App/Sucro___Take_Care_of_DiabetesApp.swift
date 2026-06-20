//___FILEHEADER___

import SwiftUI
import CoreData

@main
struct SucroApp: App {
    let persistenceController = PersistenceController.shared
    
    // Add this: Create the view model as StateObject
    @StateObject private var monitorViewModel: MonitorViewModel
    @StateObject private var settings = SettingsStore.shared

    init() {
        // Initialize with the persistence context
        let context = persistenceController.container.viewContext
        _monitorViewModel = StateObject(wrappedValue: MonitorViewModel(context: context))
    }

    var body: some Scene {
        WindowGroup {
            AppNavigationView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(monitorViewModel) // ✅ Inject here
                .environmentObject(settings)
                .preferredColorScheme(settings.preferredColorScheme)
                .task {
                    // Ask for Apple Health access so logged data can mirror there.
                    // Skipped during UI tests to avoid the system permission sheet.
                    if !ProcessInfo.processInfo.arguments.contains("-uiTesting") {
                        HealthKitManager.shared.requestAuthorization()
                    }
                }
        }
    }
}
