//
//  EventDetailView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import SwiftUI

struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsStore.self) private var settings
    let event: TimelineEvent
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onAddNote: () -> Void

    @State private var showingDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Event Icon & Type
                    VStack(spacing: 12) {
                        Image(systemName: event.icon)
                            .font(.system(size: 60))
                            .foregroundStyle(event.color)
                        
                        Text(event.title)
                            .font(.title)
                            .bold()
                        
                        if let subtitle = event.subtitle {
                            Text(subtitle)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    
                    // Timestamp & Glucose
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(icon: "clock", label: "Time", value: event.timestamp.formatted(date: .abbreviated, time: .shortened))
                        if let glucose = event.glucoseValue {
                            DetailRow(icon: "drop.fill", label: "Glucose", value: settings.formattedGlucose(glucose))
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(.rect(cornerRadius: 12))
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button(action: onAddNote) {
                            HStack {
                                Image(systemName: "note.text")
                                Text("Add Note")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(.rect(cornerRadius: 8))
                        }
                        
                        Button(action: onEdit) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Event")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .foregroundStyle(.orange)
                            .clipShape(.rect(cornerRadius: 8))
                        }
                        
                        Button(action: {
                            showingDeleteConfirm = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Event")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(.rect(cornerRadius: 8))
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Event", isPresented: $showingDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This can't be undone.")
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            Text(label)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    EventDetailView(
        event: TimelineEvent(
            type: .meal,
            timestamp: Date(),
            glucoseValue: 120,
            title: "Lunch",
            subtitle: "45g carbs"
        ),
        onEdit: {},
        onDelete: {},
        onAddNote: {}
    )
    .environment(SettingsStore())
}
