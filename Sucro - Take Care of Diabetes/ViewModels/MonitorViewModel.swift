//
//  MonitorViewModel.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import Foundation
import CoreData

@MainActor
@Observable
class MonitorViewModel: BaseViewModel {
    var glucoseReadings: [GlucoseReading] = []
    var timeRange: TimeRange = .day {
        didSet { fetchDataForTimeRange() }
    }
    var averageGlucose: Double = 0.0
    var glucoseRange: (min: Double, max: Double) = (0, 0)
    var timeInRange: Double = 0.0
    var trendData: [GlucoseTrendPoint] = []
    
    struct GlucoseTrendPoint: Identifiable {
        let id = UUID()
        let timestamp: Date
        let value: Double
    }
    
    private let settings = SettingsStore.shared

    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }
    
    
    func fetchDataForTimeRange() {
        let range = timeRange.interval()
        fetchGlucoseReadings(from: range.start, to: range.end)
        calculateStatistics()
        generateTrendData()
    }
    
    private func fetchGlucoseReadings(from start: Date, to end: Date) {
        let request: NSFetchRequest<GlucoseReading> = GlucoseReading.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReading.timestamp, ascending: true)]
        
        do {
            glucoseReadings = try viewContext.fetch(request)
        } catch {
            print("Error fetching glucose readings: \(error)")
        }
    }
    
    private func calculateStatistics() {
        guard !glucoseReadings.isEmpty else {
            averageGlucose = 0
            glucoseRange = (0, 0)
            timeInRange = 0
            return
        }
        
        let values = glucoseReadings.map { $0.value }
        averageGlucose = values.reduce(0, +) / Double(values.count)
        glucoseRange = (values.min() ?? 0, values.max() ?? 0)
        
        let inRangeCount = values.filter { settings.isInTargetRange($0) }.count
        timeInRange = (Double(inRangeCount) / Double(values.count)) * 100
    }
    
    private func generateTrendData() {
        trendData = glucoseReadings.map { reading in
            GlucoseTrendPoint(timestamp: reading.timestamp ?? Date(), value: reading.value)
        }
    }
}
