//
//  AppNavigationView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

/// The main tabs, plus the More sheet that holds the secondary tabs.
struct AppNavigationView: View {
    @State private var showingSecondary = false

    var body: some View {
        MainTabView(showMore: showMore)
            .sheet(isPresented: $showingSecondary) {
                SecondaryTabView()
            }
    }

    private func showMore() {
        showingSecondary = true
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    AppNavigationView()
        .environment(\.managedObjectContext, context)
        .environment(MonitorViewModel(context: context))
        .environment(SettingsStore())
}
