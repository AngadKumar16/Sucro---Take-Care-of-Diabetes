//
//  ExportService.swift
//  DiabetesCare
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation
import OSLog
import UIKit
import CoreData

// MARK: - Export Errors
enum ExportError: LocalizedError {
    case noDataAvailable
    case pdfGenerationFailed
    case fileWriteFailed
    
    var errorDescription: String? {
        switch self {
        case .noDataAvailable:
            return "There's nothing to export yet."
        case .pdfGenerationFailed:
            return "Couldn't create the PDF."
        case .fileWriteFailed:
            return "Couldn't save the file."
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
        dateRange: DateInterval
    ) throws -> URL {
        guard !glucoseReadings.isEmpty || !insulinEntries.isEmpty || !carbEntries.isEmpty else {
            throw ExportError.noDataAvailable
        }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("DiabetesCare_Report_\(formattedDate()).pdf")
        
        // PDF page size: Letter (612 x 792 points)
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        do {
            try renderer.writePDF(to: tempURL) { context in
                // Page 1: Title Page
                context.beginPage()
                self.drawTitlePage(in: context.pdfContextBounds, dateRange: dateRange)
                
                // Page 2: Summary Statistics
                context.beginPage()
                self.drawSummaryPage(
                    in: context.pdfContextBounds,
                    readings: glucoseReadings,
                    insulin: insulinEntries,
                    carbs: carbEntries
                )
                
                // The typical day, when there are enough days of readings.
                let profile = AGP.profile(samples: glucoseReadings.compactMap(\.sample))
                if !profile.isEmpty {
                    context.beginPage()
                    self.drawAGPPage(in: context.pdfContextBounds, buckets: profile)
                }

                // Page 3+: Data Tables (if needed, split across pages)
                if !glucoseReadings.isEmpty {
                    context.beginPage()
                    self.drawGlucoseDataPage(in: context.pdfContextBounds, readings: glucoseReadings)
                }

                // Questions saved for the visit, last so they're easy to find.
                let questions = KitStore.shared.openQuestions.map(\.text)
                if !questions.isEmpty {
                    context.beginPage()
                    self.drawQuestionsPage(in: context.pdfContextBounds, questions: questions)
                }
            }
            
            return tempURL
        } catch {
            Log.export.error("PDF generation error: \(error.localizedDescription, privacy: .public)")
            throw ExportError.pdfGenerationFailed
        }
    }
    
    // MARK: - CSV Export
    
    func exportToCSV(glucoseReadings: [GlucoseReading]) throws -> URL {
        guard !glucoseReadings.isEmpty else {
            throw ExportError.noDataAvailable
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
            .appendingPathComponent("DiabetesCare_Glucose_\(formattedDate()).csv")
        
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            Log.export.error("CSV export error: \(error.localizedDescription, privacy: .public)")
            throw ExportError.fileWriteFailed
        }
    }
    
    // MARK: - Private Drawing Methods
    
    private func drawTitlePage(in bounds: CGRect, dateRange: DateInterval) {
        let title = "DiabetesCare Health Report"
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
        let info = "Generated by DiabetesCare"
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
            ("Average Glucose", "\(avgGlucose.formatted(.number.precision(.fractionLength(0)))) mg/dL"),
            ("Time in Range", "\(timeInRange.formatted(.number.precision(.fractionLength(0))))%"),
            ("Total Insulin", "\(totalInsulin.formatted(.number.precision(.fractionLength(1)))) units"),
            ("Total Carbs", "\(totalCarbs.formatted(.number.precision(.fractionLength(0)))) g")
        ]
        
        var yOffset: CGFloat = 100
        for (label, value) in stats {
            // Box background - FIX: Use explicit CGSize for corner radii
            let boxRect = CGRect(x: 50, y: yOffset, width: 250, height: 60)
            UIColor.systemGray6.setFill()
            
            // FIX: Use bezierPathWithRoundedRect with explicit CGSize
            let path = UIBezierPath(
                roundedRect: boxRect,
                byRoundingCorners: .allCorners,
                cornerRadii: CGSize(width: 8.0, height: 8.0)
            )
            path.fill()
            
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
    
    /// Median and percentile bands by time of day, drawn on a 24-hour axis.
    private func drawAGPPage(in bounds: CGRect, buckets: [AGP.Bucket]) {
        let settings = SettingsStore.shared
        "Typical Day (Ambulatory Glucose Profile)".draw(at: CGPoint(x: 50, y: 50), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 22), .foregroundColor: UIColor.label,
        ])
        "Every day in this report folded onto one 24-hour clock. Line: median. Dark band: 25–75%. Light band: 5–95%.".draw(
            in: CGRect(x: 50, y: 84, width: bounds.width - 100, height: 40),
            withAttributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.secondaryLabel]
        )
        guard let cg = UIGraphicsGetCurrentContext() else { return }
        let plot = CGRect(x: 80, y: 140, width: bounds.width - 130, height: 320)
        let low = 40.0, high = max(300, (buckets.map(\.p95).max() ?? 300) + 20)
        func x(_ minute: Int) -> CGFloat { plot.minX + plot.width * CGFloat(minute) / 1440 }
        func y(_ mgdl: Double) -> CGFloat { plot.maxY - plot.height * CGFloat((mgdl - low) / (high - low)) }

        // Target band and frame.
        let green = UIColor(red: 0.12, green: 0.42, blue: 0.29, alpha: 1)
        cg.setFillColor(green.withAlphaComponent(0.08).cgColor)
        cg.fill(CGRect(x: plot.minX, y: y(settings.targetHigh), width: plot.width, height: y(settings.targetLow) - y(settings.targetHigh)))
        cg.setStrokeColor(UIColor.separator.cgColor)
        cg.stroke(plot)

        func band(_ lower: KeyPath<AGP.Bucket, Double>, _ upper: KeyPath<AGP.Bucket, Double>, alpha: CGFloat) {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x(buckets[0].minute), y: y(buckets[0][keyPath: upper])))
            for bucket in buckets.dropFirst() { path.addLine(to: CGPoint(x: x(bucket.minute), y: y(bucket[keyPath: upper]))) }
            for bucket in buckets.reversed() { path.addLine(to: CGPoint(x: x(bucket.minute), y: y(bucket[keyPath: lower]))) }
            path.closeSubpath()
            cg.addPath(path)
            cg.setFillColor(green.withAlphaComponent(alpha).cgColor)
            cg.fillPath()
        }
        band(\.p5, \.p95, alpha: 0.15)
        band(\.p25, \.p75, alpha: 0.35)
        let median = CGMutablePath()
        median.move(to: CGPoint(x: x(buckets[0].minute), y: y(buckets[0].median)))
        for bucket in buckets.dropFirst() { median.addLine(to: CGPoint(x: x(bucket.minute), y: y(bucket.median))) }
        cg.addPath(median)
        cg.setStrokeColor(green.cgColor)
        cg.setLineWidth(2.5)
        cg.strokePath()

        // Axis labels.
        let label: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.secondaryLabel]
        for hour in stride(from: 0, through: 24, by: 3) {
            let text = hour == 24 ? "12a" : Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!.formatted(.dateTime.hour())
            text.draw(at: CGPoint(x: x(hour * 60) - 8, y: plot.maxY + 6), withAttributes: label)
        }
        for value in stride(from: 50.0, through: high, by: 50) {
            settings.glucoseValueString(value).draw(at: CGPoint(x: plot.minX - 34, y: y(value) - 6), withAttributes: label)
        }
        "\(settings.glucoseUnit) · target \(settings.glucoseValueString(settings.targetLow))–\(settings.glucoseValueString(settings.targetHigh)) shaded".draw(
            at: CGPoint(x: plot.minX, y: plot.maxY + 24), withAttributes: label)
    }

    private func drawQuestionsPage(in bounds: CGRect, questions: [String]) {
        "Questions for the Visit".draw(at: CGPoint(x: 50, y: 50), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 22), .foregroundColor: UIColor.label,
        ])
        var top: CGFloat = 96
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.label]
        for (index, question) in questions.enumerated() {
            let text = "\(index + 1). \(question)" as NSString
            let rect = text.boundingRect(with: CGSize(width: bounds.width - 100, height: .greatestFiniteMagnitude),
                                         options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            guard top + rect.height < bounds.height - 50 else { break }
            text.draw(in: CGRect(x: 50, y: top, width: bounds.width - 100, height: rect.height), withAttributes: attributes)
            top += rect.height + 12
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
        let colX: [CGFloat] = [50, 200, 300, 400]
        let headers = ["Time", "Value", "Unit", "Trend"]
        
        for (index, header) in headers.enumerated() {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .foregroundColor: UIColor.label
            ]
            header.draw(at: CGPoint(x: colX[index], y: headerY), withAttributes: attributes)
        }
        
        // Divider line - FIX: Use explicit UIBezierPath initialization
        UIColor.systemGray3.setStroke()
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: 50, y: headerY + 20))
        linePath.addLine(to: CGPoint(x: 550, y: headerY + 20))
        linePath.lineWidth = 1.0
        linePath.stroke()
        
        // Data rows (limit to fit page)
        let yOffset: CGFloat = headerY + 30
        let rowHeight: CGFloat = 20
        let maxRows = Int((bounds.height - yOffset - 50) / rowHeight)
        
        for (index, reading) in readings.prefix(maxRows).enumerated() {
            let rowY = yOffset + (CGFloat(index) * rowHeight)
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.label
            ]
            
            let time = formattedTime(reading.timestamp)
            let value = reading.value.formatted(.number.precision(.fractionLength(0)))
            let unit = reading.unit ?? "mg/dL"
            let trend = reading.trend ?? "-"
            
            let rowData = [time, value, unit, trend]
            for (colIndex, text) in rowData.enumerated() {
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
