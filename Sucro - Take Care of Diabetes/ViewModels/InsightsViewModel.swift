//
//  InsightsViewModel.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation
import CoreData
import Combine
import Charts

@MainActor
class InsightsViewModel: BaseViewModel {
    @Published var timeRange: TimeRange = .week
    @Published var glucoseStats = GlucoseStatistics()
    @Published var insulinStats = InsulinStatistics()
    @Published var carbStats = CarbStatistics()
    @Published var correlations: [DataCorrelation] = []
    @Published var trends: [GlucoseTrend] = []
    
    enum TimeRange: String, CaseIterable {
        case day = "1 Day"
        case week = "1 Week"
        case month = "1 Month"
        case quarter = "3 Months"
        case year = "1 Year"
        
        var days: Int {
            switch self {
            case .day: return 1
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            }
        }
    }
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
        fetchInsights()
    }
    
    func fetchInsights() {
        fetchGlucoseStatistics()
        fetchInsulinStatistics()
        fetchCarbStatistics()
        fetchCorrelations()
        fetchTrends()
    }
    
    private func fetchGlucoseStatistics() {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -timeRange.days, to: Date())!
        
        let request: NSFetchRequest<GlucoseReading> = GlucoseReading.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@", startDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReading.timestamp, ascending: true)]
        
        do {
            let readings = try viewContext.fetch(request)
            glucoseStats = GlucoseCalculator.calculateStatistics(readings: readings)
        } catch {
            print("Error fetching glucose statistics: \(error)")
        }
    }
    
    private func fetchInsulinStatistics() {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -timeRange.days, to: Date())!
        
        let request: NSFetchRequest<InsulinEntry> = InsulinEntry.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@", startDate as NSDate)
        
        do {
            let entries = try viewContext.fetch(request)
            let totalUnits = entries.reduce(0) { $0 + $1.units }
            let bolusUnits = entries.filter { $0.type == "bolus" }.reduce(0) { $0 + $1.units }
            
            insulinStats = InsulinStatistics(
                totalUnits: totalUnits,
                bolusUnits: bolusUnits,
                basalUnits: totalUnits - bolusUnits,
                averageDailyUnits: totalUnits / Double(timeRange.days)
            )
        } catch {
            print("Error fetching insulin statistics: \(error)")
        }
    }
    
    private func fetchCarbStatistics() {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -timeRange.days, to: Date())!
        
        let request: NSFetchRequest<CarbEntry> = CarbEntry.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@", startDate as NSDate)
        
        do {
            let entries = try viewContext.fetch(request)
            let totalCarbs = entries.reduce(0) { $0 + $1.grams }
            
            carbStats = CarbStatistics(
                totalGrams: totalCarbs,
                averageDailyGrams: totalCarbs / Double(timeRange.days),
                averagePerMeal: entries.isEmpty ? 0 : totalCarbs / Double(entries.count)
            )
        } catch {
            print("Error fetching carb statistics: \(error)")
        }
    }
    
    private func fetchCorrelations() {
        // Find correlations between meals and glucose spikes
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -timeRange.days, to: Date())!
        
        let carbRequest: NSFetchRequest<CarbEntry> = CarbEntry.fetchRequest()
        carbRequest.predicate = NSPredicate(format: "timestamp >= %@", startDate as NSDate)
        carbRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CarbEntry.timestamp, ascending: true)]
        
        let glucoseRequest: NSFetchRequest<GlucoseReading> = GlucoseReading.fetchRequest()
        glucoseRequest.predicate = NSPredicate(format: "timestamp >= %@", startDate as NSDate)
        glucoseRequest.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReading.timestamp, ascending: true)]
        
        do {
            let carbEntries = try viewContext.fetch(carbRequest)
            let glucoseReadings = try viewContext.fetch(glucoseRequest)
            
            correlations = analyzeCorrelations(carbEntries: carbEntries, glucoseReadings: glucoseReadings)
        } catch {
            print("Error fetching correlations: \(error)")
        }
    }
    
    private func fetchTrends() {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -30, to: Date())! // Last 30 days
        
        let request: NSFetchRequest<GlucoseReading> = GlucoseReading.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@", startDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GlucoseReading.timestamp, ascending: true)]
        
        do {
            let readings = try viewContext.fetch(request)
            trends = calculateTrends(readings: readings)
        } catch {
            print("Error fetching trends: \(error)")
        }
    }
    
    private func analyzeCorrelations(carbEntries: [CarbEntry], glucoseReadings: [GlucoseReading]) -> [DataCorrelation] {
        var correlations: [DataCorrelation] = []
        
        // Simple correlation analysis
        for carbEntry in carbEntries {
            let timeWindow = DateInterval(start: carbEntry.timestamp ?? Date(), duration: 3600) // 1 hour after meal
            
            let relevantReadings = glucoseReadings.filter { reading in
                guard let timestamp = reading.timestamp else { return false }
                return timeWindow.contains(timestamp)
            }
            
            if let maxGlucose = relevantReadings.max(by: { $0.value < $1.value }) {
                let spikeMagnitude = maxGlucose.value - (relevantReadings.first?.value ?? 100)
                
                correlations.append(DataCorrelation(
                    factor: "Carbohydrates",
                    value: carbEntry.grams,
                    effect: spikeMagnitude,
                    description: "\(Int(carbEntry.grams))g carbs led to \(Int(spikeMagnitude)) mg/dL spike"
                ))
            }
        }
        
        return correlations.sorted { $0.effect > $1.effect }.prefix(5).map { $0 }
    }
    
    private func calculateTrends(readings: [GlucoseReading]) -> [GlucoseTrend] {
        var trends: [GlucoseTrend] = []
        
        // Group readings by day
        let groupedReadings = Dictionary(grouping: readings) { reading in
            Calendar.current.dateComponents([.year, .month, .day], from: reading.timestamp ?? Date())
        }
        
        for (dateComponents, dayReadings) in groupedReadings {
            if !dayReadings.isEmpty {
                let average = dayReadings.reduce(0) { $0 + $1.value } / Double(dayReadings.count)
                let trend = GlucoseCalculator.calculateTrend(readings: Array(dayReadings))
                
                trends.append(GlucoseTrend(
                    date: Calendar.current.date(from: dateComponents) ?? Date(),
                    average: average,
                    trend: trend,
                    min: dayReadings.min(by: { $0.value < $1.value })?.value ?? 0,
                    max: dayReadings.max(by: { $0.value < $1.value })?.value ?? 0
                ))
            }
        }
        
        return trends.sorted { $0.date > $1.date }
    }
}

struct GlucoseStatistics {
    let average: Double
    let standardDeviation: Double
    let cv: Double
    let timeInRange: (percentage: Double, hours: Double)
    let timeBelowRange: (percentage: Double, hours: Double)
    let timeAboveRange: (percentage: Double, hours: Double)
    
    init(average: Double = 0, standardDeviation: Double = 0, cv: Double = 0, 
         timeInRange: (percentage: Double, hours: Double) = (percentage: 0, hours: 0),
         timeBelowRange: (percentage: Double, hours: Double) = (percentage: 0, hours: 0),
         timeAboveRange: (percentage: Double, hours: Double) = (percentage: 0, hours: 0)) {
        self.average = average
        self.standardDeviation = standardDeviation
        self.cv = cv
        self.timeInRange = timeInRange
        self.timeBelowRange = timeBelowRange
        self.timeAboveRange = timeAboveRange
    }
}

struct InsulinStatistics {
    let totalUnits: Double
    let bolusUnits: Double
    let basalUnits: Double
    let averageDailyUnits: Double
    
    init(totalUnits: Double = 0, bolusUnits: Double = 0, basalUnits: Double = 0, averageDailyUnits: Double = 0) {
        self.totalUnits = totalUnits
        self.bolusUnits = bolusUnits
        self.basalUnits = basalUnits
        self.averageDailyUnits = averageDailyUnits
    }
}

struct CarbStatistics {
    let totalGrams: Double
    let averageDailyGrams: Double
    let averagePerMeal: Double
    
    init(totalGrams: Double = 0, averageDailyGrams: Double = 0, averagePerMeal: Double = 0) {
        self.totalGrams = totalGrams
        self.averageDailyGrams = averageDailyGrams
        self.averagePerMeal = averagePerMeal
    }
}

struct DataCorrelation {
    let factor: String
    let value: Double
    let effect: Double
    let description: String
}

struct GlucoseTrend {
    let date: Date
    let average: Double
    let trend: GlucoseTrend
    let min: Double
    let max: Double
}
