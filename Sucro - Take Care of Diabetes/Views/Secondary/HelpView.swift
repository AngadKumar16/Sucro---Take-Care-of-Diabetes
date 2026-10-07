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

        var content: String {
            switch self {
            case .gettingStarted:
                return "Home shows your latest glucose, how much insulin is still active, and shortcuts for common entries. Log is where you record readings, meals, insulin, and activity. Monitor charts your glucose over time."
            case .logging:
                return "The Log Meal, Quick Bolus, and Change Site buttons on Home are the fastest way to log. For more detail, use the Log tab. Press and hold Log Meal to pick a saved meal. Sucro also saves what you log to Apple Health."
            case .cgm:
                return "Connect and disconnect devices from the Devices screen. That's also where you turn Auto-sync, Background Monitoring, and Low Battery Alerts on or off. If a device stops sending data, follow the troubleshooting steps to reconnect it."
            case .insights:
                return "Insights shows whether your average glucose is going up or down, which meals are followed by big rises, and your time in range. Time in range is the share of readings between the target low and high you set in Settings."
            case .emergency:
                return "For a low, eat 15g of fast-acting carbs and check again after 15 minutes. If someone is unconscious, a caregiver should give glucagon and call emergency services. You can open your Medical ID from Help > Emergency Medical ID."
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
                        NavigationLink {
                            FAQDetailView(question: section.rawValue, answer: section.content)
                        } label: {
                            Label(section.rawValue, systemImage: section.icon)
                        }
                    }
                }

                // Popular Topics
                Section("Popular Topics") {
                    NavigationLink {
                        FAQDetailView(question: "Quick Logging in 30 Seconds", answer: HelpSection.logging.content)
                    } label: {
                        TutorialRow(title: "Quick Logging in 30 Seconds", duration: "1 min read")
                    }
                    NavigationLink {
                        FAQDetailView(question: "Setting Up Your CGM", answer: HelpSection.cgm.content)
                    } label: {
                        TutorialRow(title: "Setting Up Your CGM", duration: "1 min read")
                    }
                    NavigationLink {
                        FAQDetailView(question: "Understanding Time in Range", answer: HelpSection.insights.content)
                    } label: {
                        TutorialRow(title: "Understanding Time in Range", duration: "1 min read")
                    }
                }
                
                // FAQ
                Section("Frequently Asked Questions") {
                    NavigationLink("How do I export data?") {
                        FAQDetailView(question: "How do I export data?", answer: "Open Reports, pick a time period, and tap Export as PDF. Share with Doctor sends the same PDF. To get your raw readings as a spreadsheet, use Export Data in Settings.")
                    }
                    NavigationLink("What does Time in Range mean?") {
                        FAQDetailView(question: "What does Time in Range mean?", answer: "It's the percentage of your readings that fall inside your target range. The default range is 70 to 180 mg/dL, and you can change it in Settings. Most people aim for 70% or more.")
                    }
                    NavigationLink("How often should I change my site?") {
                        FAQDetailView(question: "How often should I change my site?", answer: "Most infusion sites need changing every 2 to 3 days. When you log a site change, Sucro reminds you when the next one is due.")
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
    @EnvironmentObject private var settings: SettingsStore

    private let dataService = DataService.shared

    var body: some View {
        NavigationView {
            List {
                Section("Medical Information") {
                    LabeledContent("Name", value: settings.userName)
                    LabeledContent("Condition", value: settings.diabetesType)
                    LabeledContent("Blood Type", value: "—")
                }

                Section("Latest Glucose") {
                    if let latest = dataService.fetchLatestGlucoseReading(context: viewContext) {
                        LabeledContent("Value", value: settings.formattedGlucose(latest.value))
                        LabeledContent("Logged", value: latest.timestamp?.formatted() ?? "—")
                    } else {
                        Text("No readings recorded")
                            .foregroundColor(.secondary)
                    }
                }

                Section("In an Emergency") {
                    Label("If this person is unconscious, call emergency services", systemImage: "phone.fill")
                        .foregroundColor(.red)
                    Text("For a severe low, give glucagon if you have it and get medical help right away.")
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
            Image(systemName: "book.fill")
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