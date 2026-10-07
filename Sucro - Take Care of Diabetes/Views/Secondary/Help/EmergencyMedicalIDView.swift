//
//  EmergencyMedicalIDView.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

import CoreData

struct EmergencyMedicalIDView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(SettingsStore.self) private var settings

    private let dataService = DataService.shared

    var body: some View {
        NavigationStack {
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
                            .foregroundStyle(.secondary)
                    }
                }

                Section("In an Emergency") {
                    Label("If this person is unconscious, call emergency services", systemImage: "phone.fill")
                        .foregroundStyle(.red)
                    Text("For a severe low, give glucagon if you have it and get medical help right away.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
