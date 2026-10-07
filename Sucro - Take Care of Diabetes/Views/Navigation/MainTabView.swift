//
//  MainTabView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct MainTabView: View {
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var logViewModel: LogViewModel
    @StateObject private var monitorViewModel: MonitorViewModel
    
    init(context: NSManagedObjectContext) {
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(context: context))
        _logViewModel = StateObject(wrappedValue: LogViewModel(context: context))
        _monitorViewModel = StateObject(wrappedValue: MonitorViewModel(context: context))
    }
    
    var body: some View {
        TabView {
            HomeView()
                .environmentObject(homeViewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            LogView()
                .environmentObject(logViewModel)
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Log")
                }
            
            MonitorView()
                .environmentObject(monitorViewModel)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Monitor")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView(context: PersistenceController.preview.container.viewContext)
}
