//
//  MiniTimelineView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData
import Charts

struct MiniTimelineView: View {
    let glucoseReadings: [GlucoseReading]
    let events: [TimelineEvent]
    let onExpand: () -> Void
    let onEventTap: (TimelineEvent) -> Void
    
    @State private var selectedEvent: TimelineEvent?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            chartContainer
        }
        .padding(.horizontal, 16)
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event)
        }
    }
    
    private var headerView: some View {
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
    }
    
    private var chartContainer: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                chartContent(geometry: geometry)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        if value.translation.width < -50 {
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
    
    private func chartContent(geometry: GeometryProxy) -> some View {
        let chartWidth = max(geometry.size.width * 2, 400)
        let chartHeight: CGFloat = 120
        
        return ZStack {
            glucoseChart(width: chartWidth, height: chartHeight)
            eventOverlays(chartWidth: chartWidth, chartHeight: chartHeight)
        }
    }
    
    private func glucoseChart(width: CGFloat, height: CGFloat) -> some View {
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
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel("\(Int(value.as(Double.self) ?? 0))")
            }
        }
        .chartYScale(domain: 40...300)
        .frame(width: width, height: height)
    }
    
    private func eventOverlays(chartWidth: CGFloat, chartHeight: CGFloat) -> some View {
        ForEach(events) { event in
            EventMarker(
                event: event,
                chartWidth: chartWidth,
                chartHeight: chartHeight,
                onTap: { selectedEvent = event }
            )
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
        return chartWidth * 0.5
    }
    
    private var yPosition: CGFloat {
        let normalizedValue = (event.glucoseValue - 40) / (300 - 40)
        return CGFloat(normalizedValue) * chartHeight
    }
}

struct EventDetailView: View {
    let event: TimelineEvent
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
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
                
                if let subtitle = event.subtitle {
                    Text(subtitle)
                        .font(.body)
                }
                
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

// Helper function for preview
func sampleGlucoseReading(value: Double, offset: Int, context: NSManagedObjectContext) -> GlucoseReading {
    let reading = GlucoseReading(context: context)
    reading.value = value
    reading.unit = "mg/dL"
    reading.timestamp = Date().addingTimeInterval(TimeInterval(offset * 3600))
    reading.trend = "stable"
    return reading
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    MiniTimelineView(
        glucoseReadings: [
            sampleGlucoseReading(value: 95, offset: -6, context: context),
            sampleGlucoseReading(value: 120, offset: -5, context: context),
            sampleGlucoseReading(value: 140, offset: -4, context: context),
            sampleGlucoseReading(value: 110, offset: -3, context: context),
            sampleGlucoseReading(value: 105, offset: -2, context: context),
            sampleGlucoseReading(value: 98, offset: -1, context: context),
            sampleGlucoseReading(value: 104, offset: 0, context: context)
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
