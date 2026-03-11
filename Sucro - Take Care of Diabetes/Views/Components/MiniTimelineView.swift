//
//  MiniTimelineView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import Charts

struct MiniTimelineView: View {
    let glucoseReadings: [GlucoseReading]
    let events: [TimelineEvent]
    let onExpand: () -> Void
    let onEventTap: (TimelineEvent) -> Void
    
    @State private var selectedEvent: TimelineEvent?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Glucose Timeline")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Expand") {
                    onExpand()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Chart Container
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack {
                        // Glucose Line Chart
                        Chart(glucoseReadings.prefix(24)) { reading in
                            LineMark(
                                x: .value("Time", reading.timestamp ?? Date()),
                                y: .value("Glucose", reading.value)
                            )
                            .foregroundStyle(.blue)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            
                            PointMark(
                                x: .value("Time", reading.timestamp ?? Date()),
                                y: .value("Glucose", reading.value)
                            )
                            .foregroundStyle(.blue)
                            .symbolSize(30)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .hour, count: 2)) { value in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.hour(.defaultDigits(amortization: .zero)))
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine()
                                AxisValueLabel("\(Int(value.as(Double.self) ?? 0))")
                            }
                        }
                        .chartYScale(domain: 40...300)
                        .frame(width: max(geometry.size.width * 2, 400), height: 120)
                        
                        // Event Overlays
                        ForEach(events) { event in
                            EventMarker(
                                event: event,
                                chartWidth: max(geometry.size.width * 2, 400),
                                chartHeight: 120,
                                onTap: { selectedEvent = event }
                            )
                        }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            if value.translation.x < -50 {
                                // Swipe left to expand
                                onExpand()
                            }
                        }
                )
            }
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .padding(.horizontal, 16)
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event)
        }
    }
}

struct EventMarker: View {
    let event: TimelineEvent
    let chartWidth: CGFloat
    let chartHeight: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: event.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(event.color)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
        }
        .position(
            x: xPosition,
            y: chartHeight - yPosition
        )
        .buttonStyle(PlainButtonStyle())
    }
    
    private var xPosition: CGFloat {
        // Calculate position based on event time relative to chart range
        // This is a simplified calculation - you'd need to implement proper time scaling
        return chartWidth * 0.5 // Placeholder
    }
    
    private var yPosition: CGFloat {
        // Calculate position based on glucose value
        let normalizedValue = (event.glucoseValue - 40) / (300 - 40)
        return CGFloat(normalizedValue) * chartHeight
    }
}

struct TimelineEvent: Identifiable {
    let id = UUID()
    let type: EventType
    let timestamp: Date
    let glucoseValue: Double
    let title: String
    let subtitle: String?
    
    var icon: String {
        switch type {
        case .meal:
            return "fork.knife"
        case .bolus:
            return "syringe"
        case .siteChange:
            return "bandage"
        case .activity:
            return "figure.walk"
        }
    }
    
    var color: Color {
        switch type {
        case .meal:
            return .orange
        case .bolus:
            return .green
        case .siteChange:
            return .purple
        case .activity:
            return .blue
        }
    }
}

enum EventType {
    case meal
    case bolus
    case siteChange
    case activity
}

struct EventDetailView: View {
    let event: TimelineEvent
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Event Header
                HStack {
                    Image(systemName: event.icon)
                        .font(.title2)
                        .foregroundColor(event.color)
                    
                    VStack(alignment: .leading) {
                        Text(event.title)
                            .font(.headline)
                        
                        Text(event.timestamp, formatter: dateTimeFormatter)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Event Details
                if let subtitle = event.subtitle {
                    Text(subtitle)
                        .font(.body)
                }
                
                // Glucose Context
                VStack(alignment: .leading, spacing: 8) {
                    Text("Glucose at time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(event.glucoseValue)) mg/dL")
                        .font(.title2)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private let dateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    MiniTimelineView(
        glucoseReadings: [
            sampleGlucoseReading(value: 95, offset: -6),
            sampleGlucoseReading(value: 120, offset: -5),
            sampleGlucoseReading(value: 140, offset: -4),
            sampleGlucoseReading(value: 110, offset: -3),
            sampleGlucoseReading(value: 105, offset: -2),
            sampleGlucoseReading(value: 98, offset: -1),
            sampleGlucoseReading(value: 104, offset: 0)
        ],
        events: [
            TimelineEvent(type: .meal, timestamp: Date().addingTimeInterval(-4 * 3600), glucoseValue: 140, title: "Lunch", subtitle: "Sandwich and apple"),
            TimelineEvent(type: .bolus, timestamp: Date().addingTimeInterval(-4.5 * 3600), glucoseValue: 145, title: "Quick Bolus", subtitle: "5.0 units"),
            TimelineEvent(type: .activity, timestamp: Date().addingTimeInterval(-2 * 3600), glucoseValue: 110, title: "Walk", subtitle: "30 minutes")
        ],
        onExpand: {},
        onEventTap: { _ in }
    )
}

func sampleGlucoseReading(value: Double, offset: Int) -> GlucoseReading {
    let reading = GlucoseReading()
    reading.value = value
    reading.unit = "mg/dL"
    reading.timestamp = Date().addingTimeInterval(TimeInterval(offset * 3600))
    reading.trend = "stable"
    return reading
}
