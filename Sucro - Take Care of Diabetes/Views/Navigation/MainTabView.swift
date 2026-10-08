//
//  MainTabView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct MainTabView: View {
    @State private var selection: MainTab = .today
    // Creating these is cheap (they load data when their screen appears),
    // so it's fine that SwiftUI may evaluate this more than once.
    @State private var homeViewModel = HomeViewModel(context: PersistenceController.shared.container.viewContext)
    @State private var logViewModel = LogViewModel(context: PersistenceController.shared.container.viewContext)
    @State private var insightsViewModel = InsightsViewModel(context: PersistenceController.shared.container.viewContext)
    @State private var reportsViewModel = ReportsViewModel(context: PersistenceController.shared.container.viewContext)

    var body: some View {
        TabView(selection: $selection) {
            Tab("Today", systemImage: "house", value: .today) {
                NavigationStack {
                    HomeView(onShowAllActivity: showLog, onShowTrends: showTrends)
                        .environment(homeViewModel)
                }
            }

            Tab("Log", systemImage: "list.bullet.clipboard", value: .log) {
                NavigationStack {
                    LogView()
                        .environment(logViewModel)
                }
            }

            Tab("Trends", systemImage: "chart.xyaxis.line", value: .trends) {
                NavigationStack {
                    TrendsView()
                        .environment(insightsViewModel)
                        .environment(reportsViewModel)
                }
            }

            Tab("Learn", systemImage: "book", value: .learn) {
                NavigationStack {
                    LearnView()
                }
            }

            Tab("Settings", systemImage: "gearshape", value: .settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }

    private func showLog() {
        logViewModel.selectedDate = Date()
        logViewModel.fetchEntriesForDate(logViewModel.selectedDate)
        selection = .log
    }

    private func showTrends() {
        selection = .trends
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    MainTabView()
        .environment(\.managedObjectContext, context)
        .environment(MonitorViewModel(context: context))
        .environment(SettingsStore())
        .environment(HealthGlucoseImporter())
}
