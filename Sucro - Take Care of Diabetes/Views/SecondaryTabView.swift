//
//  SecondaryTabView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI

struct SecondaryTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            InsightsView()
                .tabItem {
                    Image(systemName: "lightbulb.fill")
                    Text("Insights")
                }
                .tag(0)
            
            ReportsView()
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
    SecondaryTabView()
}
