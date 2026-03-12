//
//  HelpView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//


//
//  HelpView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import SwiftUI

struct HelpView: View {
    @State private var selectedSection: HelpSection?
    
    enum HelpSection: String, CaseIterable {
        case gettingStarted = "Getting Started"
        case logging = "Logging Data"
        case cgm = "CGM & Devices"
        case insights = "Understanding Insights"
        case emergency = "Emergency Help"
        
        var icon: String {
            switch self {
            case .gettingStarted: return "star.fill"
            case .logging: return "square.and.pencil"
            case .cgm: return "wifi"
            case .insights: return "chart.bar.fill"
            case .emergency: return "cross.case.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                // Quick Actions Section
                Section("Quick Help") {
                    Button {
                        // Show emergency card
                    } label: {
                        Label("Emergency Medical ID", systemImage: "cross.case.fill")
                            .foregroundColor(.red)
                    }
                    
                    Button {
                        // Contact support
                    } label: {
                        Label("Contact Support", systemImage: "message.fill")
                    }
                }
                
                // Tutorial Sections
                Section("Tutorials & Guides") {
                    ForEach(HelpSection.allCases, id: \.self) { section in
                        Button {
                            selectedSection = section
                        } label: {
                            Label(section.rawValue, systemImage: section.icon)
                        }
                    }
                }
                
                // Video Tutorials
                Section("Video Tutorials") {
                    TutorialRow(title: "Quick Logging in 30 Seconds", duration: "0:30")
                    TutorialRow(title: "Setting Up Your CGM", duration: "2:15")
                    TutorialRow(title: "Understanding Time in Range", duration: "1:45")
                }
                
                // FAQ
                Section("Frequently Asked Questions") {
                    NavigationLink("How do I export data?") {
                        FAQDetailView(question: "How do I export data?", answer: "Go to Reports > Export and select your date range. You can export as PDF for your clinician.")
                    }
                    NavigationLink("What does Time in Range mean?") {
                        FAQDetailView(question: "What does Time in Range mean?", answer: "Time in Range is the percentage of time your glucose stays between 70-180 mg/dL. Higher is better.")
                    }
                    NavigationLink("How often should I change my site?") {
                        FAQDetailView(question: "How often should I change my site?", answer: "Most infusion sites should be changed every 3 days. The app will remind you based on your settings.")
                    }
                }
                
                // About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Help & Tutorials")
        }
    }
}

struct TutorialRow: View {
    let title: String
    let duration: String
    
    var body: some View {
        HStack {
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                Text(duration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct FAQDetailView: View {
    let question: String
    let answer: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(question)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(answer)
                    .font(.body)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    HelpView()
}