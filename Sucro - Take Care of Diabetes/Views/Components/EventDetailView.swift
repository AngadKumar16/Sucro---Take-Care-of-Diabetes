//
//  EventDetailView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import SwiftUI

struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let event: TimelineEvent
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onAddNote: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Event Icon & Type
                    VStack(spacing: 12) {
                        Image(systemName: event.icon)
                            .font(.system(size: 60))
                            .foregroundColor(event.color)
                        
                        Text(event.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if let subtitle = event.subtitle {
                            Text(subtitle)
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    
                    // Timestamp & Glucose
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(icon: "clock", label: "Time", value: event.timestamp.formatted(date: .abbreviated, time: .shortened))
                        DetailRow(icon: "drop.fill", label: "Glucose", value: "\(Int(event.glucoseValue)) mg/dL")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
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
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                        
                        Button(action: onEdit) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Event")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            showDeleteConfirmation()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Event")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(8)
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
        }
    }
    
    private func showDeleteConfirmation() {
        // In a real app, show alert confirmation then call onDelete
        onDelete()
        dismiss()
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(.secondary)
            
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
}
