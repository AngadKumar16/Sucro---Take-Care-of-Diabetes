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
                        .foregroundStyle(.red)
                }

                Button("Contact Support", systemImage: "message.fill", action: contactSupport)

                NavigationLink(value: HelpDestination.safety) {
                    Label("Safety Information", systemImage: "exclamationmark.shield.fill")
                }
            }
            
            // Tutorial Sections
            Section("Tutorials & Guides") {
                ForEach(HelpSection.allCases, id: \.self) { section in
                    NavigationLink(value: HelpDestination.article(HelpArticle(title: section.rawValue, body: section.content))) {
                        Label(section.rawValue, systemImage: section.icon)
                    }
                }
            }

            // Popular Topics
            Section("Popular Topics") {
                ForEach(HelpArticle.popular) { article in
                    NavigationLink(value: HelpDestination.article(article)) {
                        TutorialRow(title: article.title, duration: "1 min read")
                    }
                }
            }
            
            // FAQ
            Section("Frequently Asked Questions") {
                ForEach(HelpArticle.faq) { article in
                    NavigationLink(article.title, value: HelpDestination.article(article))
                }
            }
            
            // About
            Section {
                LabeledContent("Version", value: "1.0.0")
            }
        }
        .navigationTitle("Help & Tutorials")
        .navigationDestination(for: HelpDestination.self) { destination in
            switch destination {
            case .article(let article):
                FAQDetailView(article: article)
            case .safety:
                SafetyInfoView()
            }
        }
        .sheet(isPresented: $showEmergencyCard) {
            EmergencyMedicalIDView()
        }
    }

    private func showEmergencyID() {
        showEmergencyCard = true
    }

    private func contactSupport() {
        let subject = "Sucro Support Request"
        let body = "Describe your issue here.\n\n---\nApp Version: 1.0.0"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:support@sucroapp.com?subject=\(encodedSubject)&body=\(encodedBody)") {
            openURL(url)
        }
    }
}

#Preview {
    NavigationStack {
        HelpView()
    }
    .environment(SettingsStore())
}