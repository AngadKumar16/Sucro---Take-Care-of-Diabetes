//
//  DevicesView.swift
//  Sucro - Take Care of Diabetes
//
//  Where the app's data comes from and goes. There's no direct device
//  connection yet, so this says so rather than showing a fake one.
//

import SwiftUI

struct DevicesView: View {
    @Environment(\.openURL) private var openURL
    @State private var healthConnected = false

    private let health = HealthKitManager.shared

    var body: some View {
        List {
            Section {
                if health.isHealthDataAvailable {
                    LabeledContent("Saving to Health", value: healthConnected ? "On" : "Off")
                    Button("Open Health", systemImage: "heart.fill") {
                        if let url = URL(string: "x-apple-health://") {
                            openURL(url)
                        }
                    }
                } else {
                    Text("Apple Health isn't available on this device.")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Apple Health")
            } footer: {
                Text(healthConnected
                     ? "Glucose, carbs, insulin and workouts you log here are also saved to Apple Health."
                     : "To save what you log to Apple Health, open Settings › Apps › Health › Data Access & Devices › \(AppInfo.name) and turn the categories on.")
            }

            Section {
                ContentUnavailableView {
                    Label("No Direct Connection Yet", systemImage: "sensor")
                } description: {
                    Text("\(AppInfo.name) can't connect to a CGM or pump directly yet. Log readings and doses yourself for now.")
                }
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Devices")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            health.checkAuthorizationStatus()
            healthConnected = health.isAuthorized
        }
    }
}

#Preview {
    NavigationStack {
        DevicesView()
    }
}
