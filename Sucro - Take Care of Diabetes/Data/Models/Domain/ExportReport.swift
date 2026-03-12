//
//  ExportReport.swift
//  Sucro - Take Care of Diabetes
//

import Foundation

struct ExportReport: Identifiable, Codable {
    let id = UUID()
    var startDate: Date
    var endDate: Date
    var reportType: ReportType
    var fileURL: URL?
    var createdAt: Date
    var isPDF: Bool
    
    enum ReportType: String, Codable {
        case summary = "summary"
        case detailed = "detailed"
        case clinician = "clinician"
        case siteAnalysis = "site_analysis"
    }
    
    var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}