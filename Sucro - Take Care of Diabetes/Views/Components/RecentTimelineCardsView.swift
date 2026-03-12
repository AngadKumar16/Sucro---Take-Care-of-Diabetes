//
//  RecentTimelineCardsView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI

struct RecentTimelineCardsView: View {
    let events: [TimelineEvent]
    let onEventTap: (TimelineEvent) -> Void
    let onEventEdit: (TimelineEvent) -> Void
    let onEventDelete: (TimelineEvent) -> Void
    let onAddNote: (TimelineEvent) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 8) {
                ForEach(events.prefix(5)) { event in
                    TimelineCard(
                        event: event,
                        onTap: { onEventTap(event) },
                        onEdit: { onEventEdit(event) },
                        onDelete: { onEventDelete(event) },
                        onAddNote: { onAddNote(event) }
                    )
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

struct TimelineCard: View {
    let event: TimelineEvent
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onAddNote: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Event Icon
            Image(systemName: event.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(event.color)
                .clipShape(Circle())
            
            // Event Details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                if let subtitle = event.subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Text(event.timestamp, formatter: relativeTimeFormatter)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Glucose Context
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(event.glucoseValue))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(glucoseColor(event.glucoseValue))
                
                Text("mg/dL")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
        )
        .offset(x: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.width  // FIXED: .width not .x
                }
                .onEnded { value in
                    withAnimation(.spring()) {
                        if value.translation.width < -50 {  // FIXED: .width not .x
                            // Swipe left - show delete option
                            dragOffset = -80
                        } else if value.translation.width > 50 {  // FIXED: .width not .x
                            // Swipe right - add note
                            onAddNote()
                            dragOffset = 0
                        } else {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onTapGesture {
            if dragOffset == 0 {
                onTap()
            }
        }
        .overlay(
            // Delete/Edit buttons (shown when swiped left)
            HStack {
                Spacer()
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .offset(x: dragOffset > -40 ? 0 : dragOffset + 40)
                
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.red)
                        .clipShape(Circle())
                }
                .offset(x: dragOffset > -80 ? 0 : dragOffset + 80)
            }
            .opacity(dragOffset < -40 ? 1 : 0)
        )
        .alert("Delete Event", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this event?")
        }
    }
    
    private func glucoseColor(_ value: Double) -> Color {
        switch value {
        case 70...180:
            return .green
        case 50..<70:
            return .orange
        case 180..<250:
            return .orange
        default:
            return .red
        }
    }
}

private let relativeTimeFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter
}()

#Preview {
    VStack(spacing: 16) {
        RecentTimelineCardsView(
            events: [
                TimelineEvent(type: .meal, timestamp: Date().addingTimeInterval(-1800), glucoseValue: 145, title: "Lunch", subtitle: "Sandwich and apple"),
                TimelineEvent(type: .bolus, timestamp: Date().addingTimeInterval(-2100), glucoseValue: 150, title: "Quick Bolus", subtitle: "5.0 units"),
                TimelineEvent(type: .activity, timestamp: Date().addingTimeInterval(-3600), glucoseValue: 110, title: "Walk", subtitle: "30 minutes"),
                TimelineEvent(type: .siteChange, timestamp: Date().addingTimeInterval(-7200), glucoseValue: 95, title: "Site Change", subtitle: "Abdomen")
            ],
            onEventTap: { _ in },
            onEventEdit: { _ in },
            onEventDelete: { _ in },
            onAddNote: { _ in }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
