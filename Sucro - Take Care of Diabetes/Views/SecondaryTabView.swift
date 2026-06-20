//
//  SecondaryTabView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct SecondaryTabView: View {
    @State private var selectedTab = 0

    @StateObject private var insightsViewModel: InsightsViewModel
    @StateObject private var reportsViewModel: ReportsViewModel

    init(context: NSManagedObjectContext) {
        _insightsViewModel = StateObject(wrappedValue: InsightsViewModel(context: context))
        _reportsViewModel = StateObject(wrappedValue: ReportsViewModel(context: context))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            InsightsView()
                .environmentObject(insightsViewModel)
                .tabItem {
                    Image(systemName: "lightbulb.fill")
                    Text("Insights")
                }
                .tag(0)

            ReportsView()
                .environmentObject(reportsViewModel)
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Reports")
                }
                .tag(1)

            DevicesView()
                .tabItem {
                    Image(systemName: "iphone.radiowaves.left.and.right")
                    Text("Devices")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

#Preview {
    SecondaryTabView(context: PersistenceController.preview.container.viewContext)
}
