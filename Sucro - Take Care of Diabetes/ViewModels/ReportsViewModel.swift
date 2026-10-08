//
//  ReportsViewModel.swift
//  Sucro - Take Care of Diabetes
//
//  Backs ReportsView with real Core Data statistics and export actions.
//  Previously ReportsView showed hardcoded numbers and had no-op buttons.
//

import Foundation
import CoreData

@MainActor
@Observable
class ReportsViewModel: BaseViewModel {
    var period: TimeRange = .week {
        didSet { recalculate() }
    }

    // Display-ready summary values
    var avgGlucose: String = "--"
    var timeInRange: String = "--"
    var insulinPerDay: String = "--"
    var carbsPerDay: String = "--"
    var hasData: Bool = false

    // Export feedback
    var exportURL: URL?
    var showShareSheet = false
    var statusTitle = ""
    var statusMessage: String?
    var showStatusAlert = false
    var isExporting = false

    private let dataService = DataService.shared
    private let exportService = ExportService.shared
    private let settings = SettingsStore.shared

    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }

    private var currentRange: DateInterval {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -period.days, to: end) ?? end
        return DateInterval(start: start, end: end)
    }

    func recalculate() {
        let range = currentRange
        let readings = dataService.fetchGlucoseReadings(context: viewContext, in: range)
        let insulin = dataService.fetchInsulinEntries(context: viewContext, in: range)
        let carbs = dataService.fetchCarbEntries(context: viewContext, in: range)

        hasData = !readings.isEmpty || !insulin.isEmpty || !carbs.isEmpty

        if readings.isEmpty {
            avgGlucose = "--"
            timeInRange = "--"
        } else {
            let avg = readings.reduce(0) { $0 + $1.value } / Double(readings.count)
            avgGlucose = settings.glucoseUnit == "mmol/L"
                ? settings.displayGlucose(avg).formatted(.number.precision(.fractionLength(1)))
                : avg.formatted(.number.precision(.fractionLength(0)))

            let tir = GlucoseCalculator.calculateTimeInRange(
                samples: readings.compactMap(\.sample),
                thresholds: settings.thresholds
            )
            timeInRange = tir.percentage.formatted(.number.precision(.fractionLength(0)))
        }

        let days = Double(period.days)
        if insulin.isEmpty {
            insulinPerDay = "--"
        } else {
            let total = insulin.reduce(0) { $0 + $1.units }
            insulinPerDay = (total / days).formatted(.number.precision(.fractionLength(1)))
        }

        if carbs.isEmpty {
            carbsPerDay = "--"
        } else {
            let total = carbs.reduce(0) { $0 + $1.grams }
            carbsPerDay = (total / days).formatted(.number.precision(.fractionLength(0)))
        }
    }

    var glucoseUnitLabel: String { settings.glucoseUnit }

    // MARK: - Export Actions

    /// Generates a PDF and presents the share sheet. Used for both
    /// "Export as PDF" and "Share with Doctor".
    func exportPDF() {
        guard let url = generatePDF() else { return }
        exportURL = url
        showShareSheet = true
    }

    /// Generates a PDF and sends it straight to the system print dialog.
    func printReport() {
        guard let url = generatePDF() else { return }
        PrintHelper.printFile(at: url, jobName: "DiabetesCare \(period.rawValue) Report")
    }

    /// Builds the PDF for the current period, or shows why it couldn't.
    private func generatePDF() -> URL? {
        let range = currentRange
        let readings = dataService.fetchGlucoseReadings(context: viewContext, in: range)
        let insulin = dataService.fetchInsulinEntries(context: viewContext, in: range)
        let carbs = dataService.fetchCarbEntries(context: viewContext, in: range)

        guard !readings.isEmpty || !insulin.isEmpty || !carbs.isEmpty else {
            statusTitle = "Nothing to Export"
            statusMessage = "Nothing logged for this period yet."
            showStatusAlert = true
            return nil
        }

        isExporting = true
        defer { isExporting = false }
        do {
            let url = try exportService.exportToPDF(
                glucoseReadings: readings,
                insulinEntries: insulin,
                carbEntries: carbs,
                dateRange: range
            )
            return url
        } catch {
            statusTitle = "Couldn't Create Report"
            statusMessage = error.localizedDescription
            showStatusAlert = true
            return nil
        }
    }
}
