//
//  SettingsView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI

struct SettingsView: View {
    @State private var glucoseUnit: String = "mg/dL"
    @State private var targetRange: String = "70-180"
    @State private var notificationsEnabled: Bool = true
    @State private var darkModeEnabled: Bool = false
    @State private var dataBackupEnabled: Bool = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Profile")
                            .font(.headline)
                        
                        HStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text("AK")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Angad Kumar")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("Type 1 Diabetes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Glucose Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Glucose Settings")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            SettingsRow(title: "Unit", value: glucoseUnit) {
                                Picker("Unit", selection: $glucoseUnit) {
                                    Text("mg/dL").tag("mg/dL")
                                    Text("mmol/L").tag("mmol/L")
                                }
                            }
                            
                            SettingsRow(title: "Target Range", value: targetRange) {
                                TextField("Target Range", text: $targetRange)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Notifications
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notifications")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            ToggleRow(title: "Enable Notifications", isOn: $notificationsEnabled)
                            ToggleRow(title: "Dark Mode", isOn: $darkModeEnabled)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Data Management
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Data Management")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            ToggleRow(title: "Auto Backup", isOn: $dataBackupEnabled)
                            
                            Button(action: {
                                // Export data
                            }) {
                                HStack {
                                    Text("Export Data")
                                    Spacer()
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.caption)
                                }
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                            }
                            
                            Button(action: {
                                // Clear data
                            }) {
                                HStack {
                                    Text("Clear All Data")
                                        .foregroundColor(.red)
                                    Spacer()
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                            }
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
            .navigationTitle("Settings")
        }
    }
}

struct SettingsRow<Content: View>: View {
    let title: String
    let value: String
    let content: Content
    
    init(title: String, value: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.value = value
        self.content = content()
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            content
        }
        .padding(.vertical, 8)
    }
}

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SettingsView()
}
