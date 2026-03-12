//
//  ExportService.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation
import UIKit
import CoreData

// MARK: - Export Errors
enum ExportError: LocalizedError {
    case noDataAvailable
    case pdfGenerationFailed
    case imageConversionFailed
    case fileWriteFailed
    
    var errorDescription: String? {
        switch self {
        case .noDataAvailable:
            return "No data available to export"
        case .pdfGenerationFailed:
            return "Failed to generate PDF"
        case .imageConversionFailed:
            return "Failed to convert image"
        case .fileWriteFailed:
            return "Failed to write file to disk"
        }
    }
}

// MARK: - Export Service
class ExportService {
    
    static let shared = ExportService()
    
    private init() {}
    
    // MARK: - PDF Export
    
    func exportToPDF(
        glucoseReadings: [GlucoseReading],
        insulinEntries: [InsulinEntry],
        carbEntries: [CarbEntry],
        dateRange: DateInterval,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        // Validate data
        guard !glucoseReadings.isEmpty || !insulinEntries.isEmpty || !carbEntries.isEmpty else {
            completion(.failure(ExportError.noDataAvailable))
            return
        }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Sucro_Export_\(formattedDate()).pdf")
        
        // PDF page size: Letter (612 x 792 points)
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        do {
            try renderer.writePDF(to: tempURL) { context in
                var currentPage = 0
                
                // Page 1: Title Page
                context.beginPage()
                self.drawTitlePage(in: context.pdfContextBounds, dateRange: dateRange)
                currentPage += 1
                
                // Page 2: Summary Statistics
                context.beginPage()
                self.drawSummaryPage(
                    in: context.pdfContextBounds,
                    readings: glucoseReadings,
                    insulin: insulinEntries,
                    carbs: carbEntries
                )
                currentPage += 1
                
                // Page 3+: Data Tables (if needed, split across pages)
                if glucoseReadings.count > 0 {
                    context.beginPage()
                    self.drawGlucoseDataPage(in: context.pdfContextBounds, readings: glucoseReadings)
                }
            }
            
            completion(.success(tempURL))
        } catch {
            print("PDF generation error: \(error.localizedDescription)")
            completion(.failure(ExportError.pdfGenerationFailed))
        }
    }
    
    // MARK: - PNG Export (Snapshot)
    
    func exportSnapshotToPNG(
        view: UIView,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        // Ensure we're on main thread for UI operations
        DispatchQueue.main.async {
            let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
            let image = renderer.image { ctx in
                view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            }
            
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("Sucro_Snapshot_\(self.formattedDate()).png")
            
            do {
                guard let pngData = image.pngData() else {
                    completion(.failure(ExportError.imageConversionFailed))
                    return
                }
                try pngData.write(to: tempURL)
                completion(.success(tempURL))
            } catch {
                print("PNG export error: \(error.localizedDescription)")
                completion(.failure(ExportError.fileWriteFailed))
            }
        }
    }
    
    // MARK: - CSV Export
    
    func exportToCSV(
        glucoseReadings: [GlucoseReading],
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard !glucoseReadings.isEmpty else {
            completion(.failure(ExportError.noDataAvailable))
            return
        }
        
        var csvString = "Timestamp,Value,Unit,Trend,Notes\n"
        
        for reading in glucoseReadings {
            let timestamp = formattedTimestamp(reading.timestamp)
            let value = reading.value
            let unit = escapeCSV(reading.unit ?? "mg/dL")
            let trend = escapeCSV(reading.trend ?? "")
            let notes = escapeCSV(reading.notes ?? "")
            
            csvString.append("\(timestamp),\(value),\(unit),\(trend),\(notes)\n")
        }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Sucro_Data_\(formattedDate()).csv")
        
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            completion(.success(tempURL))
        } catch {
            print("CSV export error: \(error.localizedDescription)")
            completion(.failure(ExportError.fileWriteFailed))
        }
    }
    
    // MARK: - Private Drawing Methods
    
    private func drawTitlePage(in bounds: CGRect, dateRange: DateInterval) {
        let title = "Sucro Health Report"
        let dateString = "Period: \(formattedDate(dateRange.start)) - \(formattedDate(dateRange.end))"
        
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 32),
            .foregroundColor: UIColor.label
        ]
        title.draw(at: CGPoint(x: 50, y: 100), withAttributes: titleAttributes)
        
        // Date range
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.secondaryLabel
        ]
        dateString.draw(at: CGPoint(x: 50, y: 150), withAttributes: dateAttributes)
        
        // App info
        let infoAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        let info = "Generated by Sucro - Take Care of Diabetes"
        info.draw(at: CGPoint(x: 50, y: bounds.height - 50), withAttributes: infoAttributes)
    }
    
    private func drawSummaryPage(
        in bounds: CGRect,
        readings: [GlucoseReading],
        insulin: [InsulinEntry],
        carbs: [CarbEntry]
    ) {
        let title = "Summary Statistics"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.label
        ]
        title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
        
        // Calculate statistics
        let avgGlucose = readings.isEmpty ? 0 : readings.map { $0.value }.reduce(0, +) / Double(readings.count)
        let inRangeCount = readings.filter { $0.value >= 70 && $0.value <= 180 }.count
        let timeInRange = readings.isEmpty ? 0 : (Double(inRangeCount) / Double(readings.count)) * 100
        let totalInsulin = insulin.reduce(0) { $0 + $1.units }
        let totalCarbs = carbs.reduce(0) { $0 + $1.grams }
        
        // Draw stat boxes
        let stats = [
            ("Average Glucose", String(format: "%.0f mg/dL", avgGlucose)),
            ("Time in Range", String(format: "%.0f%%", timeInRange)),
            ("Total Insulin", String(format: "%.1f units", totalInsulin)),
            ("Total Carbs", String(format: "%.0f g", totalCarbs))
        ]
        
        var yOffset: CGFloat = 100
        for (label, value) in stats {
            // Box background
            let boxRect = CGRect(x: 50, y: yOffset, width: 250, height: 60)
            UIColor.systemGray6.setFill()
            UIBezierPath(roundedRect: boxRect, cornerRadius: 8).fill()
            
            // Label
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.secondaryLabel
            ]
            label.draw(at: CGPoint(x: 60, y: yOffset + 10), withAttributes: labelAttributes)
            
            // Value
            let valueAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: UIColor.label
            ]
            value.draw(at: CGPoint(x: 60, y: yOffset + 30), withAttributes: valueAttributes)
            
            yOffset += 80
        }
    }
    
    private func drawGlucoseDataPage(in bounds: CGRect, readings: [GlucoseReading]) {
        let title = "Glucose Readings"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor.label
        ]
        title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
        
        // Table header
        let headerY: CGFloat = 90
        let colX = [50, 200, 300, 400]
        let headers = ["Time", "Value", "Unit", "Trend"]
        
        for (index, header) in headers.enumerated() {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .foregroundColor: UIColor.label
            ]
            header.draw(at: CGPoint(x: colX[index], y: headerY), withAttributes: attributes)
        }
        
        // Divider line
        UIColor.systemGray3.setStroke()
        let line = UIBezierPath()
        line.move(to: CGPoint(x: 50, y: headerY + 20))
        line.addLine(to: CGPoint(x: 550, y: headerY + 20))
        line.stroke()
        
        // Data rows (limit to fit page)
        var yOffset: CGFloat = headerY + 30
        let rowHeight: CGFloat = 20
        let maxRows = Int((bounds.height - yOffset - 50) / rowHeight)
        
        for (index, reading) in readings.prefix(maxRows).enumerated() {
            let rowY = yOffset + (CGFloat(index) * rowHeight)
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.label
            ]
            
            let time = formattedTime(reading.timestamp)
            let value = String(format: "%.0f", reading.value)
            let unit = reading.unit ?? "mg/dL"
            let trend = reading.trend ?? "-"
            
            [time, value, unit, trend].enumerated().forEach { colIndex, text in
                text.draw(at: CGPoint(x: colX[colIndex], y: rowY), withAttributes: attributes)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formattedDate(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func formattedTimestamp(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func escapeCSV(_ string: String) -> String {
        // Escape quotes and wrap in quotes if contains comma
        var escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") {
            escaped = "\"\(escaped)\""
        }
        return escaped
    }
}
