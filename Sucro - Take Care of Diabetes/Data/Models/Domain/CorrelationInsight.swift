//
//  CorrelationInsight.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation

struct CorrelationInsight: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var correlationType: CorrelationType
    var confidence: Double // 0.0 to 1.0
    var recommendedAction: String?
    var generatedAt: Date
    
    enum CorrelationType: String, Codable {
        case mealSpike = "meal_spike"
        case exerciseImpact = "exercise_impact"
        case sitePerformance = "site_performance"
        case sleepQuality = "sleep_quality"
        case stressPattern = "stress_pattern"
    }
}
