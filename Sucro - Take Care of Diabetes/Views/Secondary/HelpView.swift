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
    @Environment(\.openURL) private var openURL
    @State private var selectedSection: HelpSection?
    @State private var showEmergencyCard = false

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
                        showEmergencyCard = true
                    } label: {
                        Label("Emergency Medical ID", systemImage: "cross.case.fill")
                            .foregroundColor(.red)
                    }

                    Button {
                        contactSupport()
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
            .sheet(isPresented: $showEmergencyCard) {
                EmergencyMedicalIDView()
            }
        }
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

struct EmergencyMedicalIDView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    private let dataService = DataService.shared

    var body: some View {
        NavigationView {
            List {
                Section("Medical Information") {
                    LabeledContent("Name", value: "Angad Kumar")
                    LabeledContent("Condition", value: "Type 1 Diabetes")
                    LabeledContent("Blood Type", value: "—")
                }

                Section("Latest Glucose") {
                    if let latest = dataService.fetchLatestGlucoseReading(context: viewContext) {
                        LabeledContent("Value", value: "\(Int(latest.value)) mg/dL")
                        LabeledContent("Logged", value: latest.timestamp?.formatted() ?? "—")
                    } else {
                        Text("No readings recorded")
                            .foregroundColor(.secondary)
                    }
                }

                Section("In an Emergency") {
                    Label("If unconscious, call emergency services", systemImage: "phone.fill")
                        .foregroundColor(.red)
                    Text("For severe low blood sugar, administer glucagon if available and seek immediate medical help.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Medical ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
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