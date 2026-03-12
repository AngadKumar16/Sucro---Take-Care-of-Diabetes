//
//  AppNavigationView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData  // ADD THIS LINE

struct AppNavigationView: View {
    @State private var showingSecondary = false
    @State private var selectedSecondaryTab = 0
    
    var body: some View {
        NavigationView {
            MainTabView(context: PersistenceController.shared.container.viewContext)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingSecondary.toggle()
                        }) {
                            Image(systemName: "ellipsis.circle")
                                .font(.title2)
                        }
                    }
                }
                .sheet(isPresented: $showingSecondary) {
                    NavigationView {
                        SecondaryTabView()
                            .navigationTitle("More")
                            .navigationBarTitleDisplayMode(.large)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") {
                                        showingSecondary = false
                                    }
                                }
                            }
                    }
                }
        }
    }
}

#Preview {
    AppNavigationView()
}
