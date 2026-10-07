//
//  SecondaryTabView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

/// The More sheet. Each tab has its own navigation stack and a Done button
/// that closes the sheet.
struct SecondaryTabView: View {
    @State private var selection: SecondaryTab = .insights
    // Creating these is cheap (they load data when their screen appears),
    // so it's fine that SwiftUI may evaluate this more than once.
    @State private var insightsViewModel = InsightsViewModel(context: PersistenceController.shared.container.viewContext)
    @State private var reportsViewModel = ReportsViewModel(context: PersistenceController.shared.container.viewContext)

    var body: some View {
        TabView(selection: $selection) {
            Tab("Insights", systemImage: "lightbulb.fill", value: .insights) {
                NavigationStack {
                    InsightsView()
                        .environment(insightsViewModel)
                        .doneButton()
                }
            }

            Tab("Reports", systemImage: "doc.text.fill", value: .reports) {
                NavigationStack {
                    ReportsView()
                        .environment(reportsViewModel)
                        .doneButton()
                }
            }

            Tab("Devices", systemImage: "iphone.radiowaves.left.and.right", value: .devices) {
                NavigationStack {
                    DevicesView()
                        .doneButton()
                }
            }

            Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                NavigationStack {
                    SettingsView()
                        .doneButton()
                }
            }

            Tab("Help", systemImage: "questionmark.circle.fill", value: .help) {
                NavigationStack {
                    HelpView()
                        .doneButton()
                }
            }
        }
        .tint(.blue)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    SecondaryTabView()
        .environment(\.managedObjectContext, context)
        .environment(SettingsStore())
}
