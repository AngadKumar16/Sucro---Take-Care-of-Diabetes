//
//  MainTabView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct MainTabView: View {
    // Shared with the full-screen Monitor opened from Home; owned by the app.
    @Environment(MonitorViewModel.self) private var monitorViewModel

    @State private var selection: MainTab = .home
    // Creating these is cheap (they load data when their screen appears),
    // so it's fine that SwiftUI may evaluate this more than once.
    @State private var homeViewModel = HomeViewModel(context: PersistenceController.shared.container.viewContext)
    @State private var logViewModel = LogViewModel(context: PersistenceController.shared.container.viewContext)

    let showMore: () -> Void

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                NavigationStack {
                    HomeView()
                        .environment(homeViewModel)
                        .moreButton(action: showMore)
                }
            }

            Tab("Log", systemImage: "plus.circle.fill", value: .log) {
                NavigationStack {
                    LogView()
                        .environment(logViewModel)
                        .moreButton(action: showMore)
                }
            }

            Tab("Monitor", systemImage: "chart.line.uptrend.xyaxis", value: .monitor) {
                NavigationStack {
                    MonitorView()
                        .environment(monitorViewModel)
                        .moreButton(action: showMore)
                }
            }
        }
        .tint(.blue)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    MainTabView(showMore: {})
        .environment(\.managedObjectContext, context)
        .environment(MonitorViewModel(context: context))
        .environment(SettingsStore())
}
