//
//  DevicesView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI

struct DevicesView: View {
    @State private var connectedDevices: [Device] = [
        Device(name: "Dexcom G6", type: "CGM", batteryLevel: 85, isConnected: true),
        Device(name: "Omnipod 5", type: "Insulin Pump", batteryLevel: 62, isConnected: true)
    ]
    @State private var availableDevices: [Device] = [
        Device(name: "Libre 3", type: "CGM", batteryLevel: 0, isConnected: false),
        Device(name: "Tandem t:slim", type: "Insulin Pump", batteryLevel: 0, isConnected: false)
    ]
    
    struct Device: Identifiable {
        let id = UUID()
        let name: String
        let type: String
        let batteryLevel: Int
        let isConnected: Bool
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Connected Devices
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Connected Devices")
                            .font(.headline)
                        
                        ForEach(connectedDevices) { device in
                            DeviceCard(device: device)
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
                        
                        ForEach(availableDevices) { device in
                            AvailableDeviceCard(device: device) {
                                // Handle connection
                                if let index = availableDevices.firstIndex(where: { $0.id == device.id }) {
                                    availableDevices.remove(at: index)
                                    connectedDevices.append(device)
                                }
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
                            SettingsButton(title: "Auto-sync", icon: "arrow.triangle.2.circlepath", isOn: true)
                            SettingsButton(title: "Background Monitoring", icon: "waveform.path.ecg", isOn: true)
                            SettingsButton(title: "Low Battery Alerts", icon: "battery.25", isOn: true)
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
                    Image(systemName: "battery.\(device.batteryLevel)")
                        .foregroundColor(device.batteryLevel > 20 ? .green : .red)
                    Text("\(device.batteryLevel)%")
                        .font(.caption)
                }
                
                Text("Connected")
                    .font(.caption)
                    .foregroundColor(.green)
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
    let isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Toggle("", isOn: .constant(isOn))
                .disabled(true)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    DevicesView()
}
