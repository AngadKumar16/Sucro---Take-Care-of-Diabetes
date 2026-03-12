//
//  MonitorViewModel.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import Foundation
import CoreData
import Combine

@MainActor
class MonitorViewModel: BaseViewModel {
    @Published var glucoseReadings: [GlucoseReading] = []
    @Published var timeRange: TimeRange = .day
    @Published var averageGlucose: Double = 0.0
    @Published var glucoseRange: (min: Double, max: Double) = (0, 0)
    @Published var timeInRange: Double = 0.0
    @Published var trendData: [GlucoseTrendPoint] = []
    
    enum TimeRange: String, CaseIterable {
        case day = "24h"
        case week = "7d"
        case month = "30d"
        case quarter = "3m"
        
        var calendarComponent: Calendar.Component {
            switch self {
            case .day: return .day
            case .week: return .weekOfYear
            case .month: return .month
            case .quarter: return .month
            }
        }
        
        var value: Int {
            switch self {
            case .day: return 1
            case .week: return 1
            case .month: return 1
            case .quarter: return 3
            }
        }
    }
    
    struct GlucoseTrendPoint: Identifiable {
        let id = UUID()
        let timestamp: Date
        let value: Double
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
        fetchDataForTimeRange()
    }
    
    func updateTimeRange(_ range: TimeRange) {
        timeRange = range
        fetchDataForTimeRange()
    }
    
    func fetchDataForTimeRange() {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: timeRange.calendarComponent, value: -timeRange.value, to: endDate)!
        
        fetchGlucoseReadings(from: startDate, to: endDate)
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
        
        let inRangeCount = values.filter { $0 >= 70 && $0 <= 180 }.count
        timeInRange = (Double(inRangeCount) / Double(values.count)) * 100
    }
    
    private func generateTrendData() {
        trendData = glucoseReadings.map { reading in
            GlucoseTrendPoint(timestamp: reading.timestamp ?? Date(), value: reading.value)
        }
    }
}
