//
//  DevicesView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI

struct DevicesView: View {
    @EnvironmentObject private var settings: SettingsStore

    struct Device: Identifiable {
        var id: String { name }
        let name: String
        let type: String
        let batteryLevel: Int
    }

    /// Full catalog of devices the app knows how to show.
    private let catalog: [Device] = [
        Device(name: "Dexcom G6", type: "CGM", batteryLevel: 85),
        Device(name: "Omnipod 5", type: "Insulin Pump", batteryLevel: 62),
        Device(name: "Libre 3", type: "CGM", batteryLevel: 90),
        Device(name: "Tandem t:slim", type: "Insulin Pump", batteryLevel: 74)
    ]

    private var connectedDevices: [Device] {
        catalog.filter { settings.connectedDeviceNames.contains($0.name) }
    }

    private var availableDevices: [Device] {
        catalog.filter { !settings.connectedDeviceNames.contains($0.name) }
    }

    private func connect(_ device: Device) {
        guard !settings.connectedDeviceNames.contains(device.name) else { return }
        settings.connectedDeviceNames.append(device.name)
    }

    private func disconnect(_ device: Device) {
        settings.connectedDeviceNames.removeAll { $0 == device.name }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Connected Devices
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Connected Devices")
                            .font(.headline)
                        
                        if connectedDevices.isEmpty {
                            Text("No devices connected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        ForEach(connectedDevices) { device in
                            DeviceCard(device: device) {
                                disconnect(device)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Available Devices
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Available Devices")
                            .font(.headline)
                        
                        if availableDevices.isEmpty {
                            Text("All known devices are connected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        ForEach(availableDevices) { device in
                            AvailableDeviceCard(device: device) {
                                connect(device)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Device Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Device Settings")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            SettingsButton(title: "Auto-sync", icon: "arrow.triangle.2.circlepath", isOn: $settings.autoSyncEnabled)
                            SettingsButton(title: "Background Monitoring", icon: "waveform.path.ecg", isOn: $settings.backgroundMonitoringEnabled)
                            SettingsButton(title: "Low Battery Alerts", icon: "battery.25", isOn: $settings.lowBatteryAlertsEnabled)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Devices")
        }
    }
}

struct DeviceCard: View {
    let device: DevicesView.Device
    let onDisconnect: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(device.type)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Image(systemName: "battery.100")
                        .foregroundColor(device.batteryLevel > 20 ? .green : .red)
                    Text("\(device.batteryLevel)%")
                        .font(.caption)
                }

                Button("Disconnect", role: .destructive, action: onDisconnect)
                    .font(.caption)
                    .buttonStyle(.borderless)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct AvailableDeviceCard: View {
    let device: DevicesView.Device
    let onConnect: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(device.type)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Connect") {
                onConnect()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct SettingsButton: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)

            Spacer()

            Toggle("", isOn: $isOn)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    DevicesView()
        .environmentObject(SettingsStore())
}
