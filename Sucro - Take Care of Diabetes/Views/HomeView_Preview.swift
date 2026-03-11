//
//  HomeView_Preview.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI

struct HomeView_Preview: View {
    @StateObject private var mockViewModel = MockHomeViewModel()
    
    var body: some View {
        HomeView()
            .environmentObject(mockViewModel)
    }
}

class MockHomeViewModel: HomeViewModel {
    override init(context: NSManagedObjectContext) {
        // Create mock context for preview
        super.init(context: NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType))
        setupMockData()
    }
    
    private func setupMockData() {
        // Mock glucose reading
        let mockGlucose = GlucoseReading()
        mockGlucose.value = 104
        mockGlucose.unit = "mg/dL"
        mockGlucose.timestamp = Date()
        mockGlucose.trend = "up"
        latestGlucoseReading = mockGlucose
        
        // Mock recent readings
        recentReadings = [
            createMockGlucose(value: 104, offset: 0),
            createMockGlucose(value: 98, offset: -1),
            createMockGlucose(value: 120, offset: -2),
            createMockGlucose(value: 140, offset: -3),
            createMockGlucose(value: 110, offset: -4)
        ]
        
        // Mock totals
        todayInsulinTotal = 25.5
        todayCarbTotal = 120.0
        insulinOnBoard = 2.5
        batteryLevel = 0.85
        lastSyncTime = Date().addingTimeInterval(-300)
        
        // Mock timeline events
        timelineEvents = [
            TimelineEvent(type: .meal, timestamp: Date().addingTimeInterval(-4 * 3600), glucoseValue: 140, title: "Lunch", subtitle: "Sandwich and apple"),
            TimelineEvent(type: .bolus, timestamp: Date().addingTimeInterval(-4.5 * 3600), glucoseValue: 145, title: "Quick Bolus", subtitle: "5.0 units"),
            TimelineEvent(type: .activity, timestamp: Date().addingTimeInterval(-2 * 3600), glucoseValue: 110, title: "Walk", subtitle: "30 minutes")
        ]
        
        // Mock reminders
        upcomingReminders = [
            Reminder(title: "Change infusion site", time: Date().addingTimeInterval(3600), type: .siteChange),
            Reminder(title: "Check CGM sensor", time: Date().addingTimeInterval(7200), type: .deviceCheck)
        ]
        
        // Mock suggestion
        smartSuggestion = "Consider changing the site - 2 days since last change"
        
        // Mock site change
        let mockSiteChange = SiteChange()
        mockSiteChange.location = "Abdomen"
        mockSiteChange.timestamp = Date().addingTimeInterval(-86400) // 1 day ago
        lastSiteChange = mockSiteChange
    }
    
    private func createMockGlucose(value: Double, offset: Int) -> GlucoseReading {
        let reading = GlucoseReading()
        reading.value = value
        reading.unit = "mg/dL"
        reading.timestamp = Date().addingTimeInterval(TimeInterval(offset * 3600))
        reading.trend = "stable"
        return reading
    }
}

#Preview {
    HomeView_Preview()
}
