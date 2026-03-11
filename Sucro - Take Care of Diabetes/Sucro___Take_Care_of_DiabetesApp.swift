//___FILEHEADER___

import SwiftUI
import CoreData

@main
struct SucroApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            AppNavigationView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
