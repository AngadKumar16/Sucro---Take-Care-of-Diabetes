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
                    LabeledContent("Name", value: settings.userName.isEmpty ? "Not set" : settings.userName)
                    LabeledContent("Condition", value: settings.diabetesType)
                }

                Section("Latest Glucose") {
                    if let latest = dataService.fetchLatestGlucoseReading(context: viewContext) {
                        LabeledContent("Value", value: settings.formattedGlucose(latest.value))
                        LabeledContent("Logged", value: latest.timestamp?.formatted(date: .abbreviated, time: .shortened) ?? "—")
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
            .safeAreaInset(edge: .bottom) {
                Text("Set your name in Settings › Profile. For a Medical ID that shows on the Lock Screen, use the Health app.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
