//
//  MainTabView.swift
//  DiabetesCare
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

/// The tabs on a parent's or caregiver's phone: the people they follow,
/// Learn and Settings.
struct CaregiverTabView: View {
    var body: some View {
        TabView {
            Tab("Family", systemImage: "person.2.fill") {
                NavigationStack {
                    FamilyHomeView()
                }
            }
            Tab("Learn", systemImage: "book") {
                NavigationStack {
                    LearnView()
                }
            }
            Tab("Settings", systemImage: "gearshape") {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
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
