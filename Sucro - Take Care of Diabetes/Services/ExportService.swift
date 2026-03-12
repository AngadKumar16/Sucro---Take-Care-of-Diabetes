//
//  ExportService.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//


//
//  ExportService.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation
import UIKit
import PDFKit
import CoreData

class ExportService {
    
    static let shared = ExportService()
    
    // MARK: - PDF Export
    
    func exportToPDF(
        glucoseReadings: [GlucoseReading],
        insulinEntries: [InsulinEntry],
        carbEntries: [CarbEntry],
        dateRange: DateInterval,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let pdfDocument = PDFDocument()
        
        // Title Page
        if let titlePage = createTitlePage(dateRange: dateRange) {
            pdfDocument.insert(titlePage, at: 0)
        }
        
        // Summary Page
        if let summaryPage = createSummaryPage(readings: glucoseReadings) {
            pdfDocument.insert(summaryPage, at: 1)
        }
        
        // Data Pages
        let dataPages = createDataPages(
            readings: glucoseReadings,
            insulin: insulinEntries,
            carbs: carbEntries
        )
        for (index, page) in dataPages.enumerated() {
            pdfDocument.insert(page, at: 2 + index)
        }
        
        // Save to temp file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Sucro_Export_\(formattedDate()).pdf")
        
        do {
            try pdfDocument.write(to: tempURL)
            completion(.success(tempURL))
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - PNG Export (Snapshot)
    
    func exportSnapshotToPNG(
        view: UIView,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        let image = renderer.image { ctx in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Sucro_Snapshot_\(formattedDate()).png")
        
        do {
            if let pngData = image.pngData() {
                try pngData.write(to: tempURL)
                completion(.success(tempURL))
            } else {
                completion(.failure(ExportError.imageConversionFailed))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - CSV Export
    
    func exportToCSV(
        glucoseReadings: [GlucoseReading],
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        var csvString = "Timestamp,Value,Unit,Trend\n"
        
        for reading in glucoseReadings {
            let timestamp = reading.timestamp?.ISO8601Format() ?? ""
            let value = reading.value
            let unit = reading.unit ?? "mg/dL"
            let trend = reading.trend ?? ""
            csvString.append("\(timestamp),\(value),\(unit),\(trend)\n")
        }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Sucro_Data_\(formattedDate()).csv")
        
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            completion(.success(tempURL))
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Private Helpers
    
    private func createTitlePage(dateRange: DateInterval) -> PDFPage? {
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792), format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let title = "Sucro Health Report"
            let dateString = "Period: \(formattedDate(dateRange.start)) - \(formattedDate(dateRange.end))"
            
            title.draw(at: CGPoint(x: 50, y: 100), withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 32)
            ])
            
            dateString.draw(at: CGPoint(x: 50, y: 150), withAttributes: [
                .font: UIFont.systemFont(ofSize: 16)
            ])
        }
        
        return PDFPage(image: UIImage(data: data) ?? UIImage())
    }
    
    private func createSummaryPage(readings: [GlucoseReading]) -> PDFPage? {
        // Simplified - would include actual statistics
        return nil
    }
    
    private func createDataPages(
        readings: [GlucoseReading],
        insulin: [InsulinEntry],
        carbs: [CarbEntry]
    ) -> [PDFPage] {
        // Simplified - would create detailed data tables
        return []
    }
    
    private func formattedDate(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

enum ExportError: Error {
    case imageConversionFailed
    case noDataAvailable
    case pdfGenerationFailed
}