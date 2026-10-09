//
//  HelpView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import SwiftUI

struct HelpView: View {
    @Environment(\.openURL) private var openURL
    @State private var showEmergencyCard = false

    var body: some View {
        List {
            // Quick Actions Section
            Section("Quick Help") {
                Button(action: showEmergencyID) {
                    Label("Emergency Medical ID", systemImage: "cross.case.fill")
                }
                .tint(.red)

                Button("Contact Support", systemImage: "message.fill", action: contactSupport)

                NavigationLink(value: HelpDestination.safety) {
                    Label("Safety Information", systemImage: "exclamationmark.shield.fill")
                }
            }
            .listRowBackground(Theme.card)
            
            // Tutorial Sections
            Section("Tutorials & Guides") {
                ForEach(HelpSection.allCases, id: \.self) { section in
                    NavigationLink(value: HelpDestination.article(HelpArticle(title: section.rawValue, body: section.content))) {
                        Label(section.rawValue, systemImage: section.icon)
                    }
                }
            }
            .listRowBackground(Theme.card)

            // FAQ
            Section("Frequently Asked Questions") {
                ForEach(HelpArticle.faq) { article in
                    NavigationLink(article.title, value: HelpDestination.article(article))
                }
            }
            .listRowBackground(Theme.card)
            
            Section {
                LabeledContent("Version", value: AppInfo.version)
            }
            
            .listRowBackground(Theme.card)
        }
        .instrumentBackground()
        .navigationTitle("Help & Tutorials")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEmergencyCard) {
            EmergencyMedicalIDView()
        }
    }

    private func showEmergencyID() {
        showEmergencyCard = true
    }

    private func contactSupport() {
        if let url = AppInfo.supportEmailURL {
            openURL(url)
        }
    }
}

#Preview {
    NavigationStack {
        HelpView()
            .helpDestinations()
    }
    .environment(SettingsStore())
}