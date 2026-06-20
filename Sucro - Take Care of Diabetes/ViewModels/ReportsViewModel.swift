//
//  ReportsViewModel.swift
//  Sucro - Take Care of Diabetes
//
//  Backs ReportsView with real Core Data statistics and export actions.
//  Previously ReportsView showed hardcoded numbers and had no-op buttons.
//

import Foundation
import CoreData
import Combine

@MainActor
class ReportsViewModel: BaseViewModel {
    enum Period: String, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case yearly = "Yearly"

        var days: Int {
            switch self {
            case .weekly: return 7
            case .monthly: return 30
            case .quarterly: return 90
            case .yearly: return 365
            }
        }
    }

    @Published var period: Period = .weekly {
        didSet { recalculate() }
    }

    // Display-ready summary values
    @Published var avgGlucose: String = "--"
    @Published var timeInRange: String = "--"
    @Published var insulinPerDay: String = "--"
    @Published var carbsPerDay: String = "--"
    @Published var hasData: Bool = false

    // Export feedback
    @Published var exportURL: URL?
    @Published var showShareSheet = false
    @Published var statusMessage: String?
    @Published var showStatusAlert = false
    @Published var isExporting = false

    private let dataService = DataService.shared
    private let exportService = ExportService.shared
    private let settings = SettingsStore.shared

    override init(context: NSManagedObjectContext) {
        super.init(context: context)
        recalculate()
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
                ? String(format: "%.1f", settings.displayGlucose(avg))
                : String(format: "%.0f", avg)

            let tir = GlucoseCalculator.calculateTimeInRange(
                readings: readings,
                targetMin: settings.targetLow,
                targetMax: settings.targetHigh
            )
            timeInRange = String(format: "%.0f", tir.percentage)
        }

        let days = Double(period.days)
        if insulin.isEmpty {
            insulinPerDay = "--"
        } else {
            let total = insulin.reduce(0) { $0 + $1.units }
            insulinPerDay = String(format: "%.1f", total / days)
        }

        if carbs.isEmpty {
            carbsPerDay = "--"
        } else {
            let total = carbs.reduce(0) { $0 + $1.grams }
            carbsPerDay = String(format: "%.0f", total / days)
        }
    }

    var glucoseUnitLabel: String { settings.glucoseUnit }

    // MARK: - Export Actions

    /// Generates a PDF and presents the share sheet. Used for both
    /// "Export as PDF" and "Share with Doctor".
    func exportPDF() {
        generatePDF { [weak self] url in
            self?.exportURL = url
            self?.showShareSheet = true
        }
    }

    /// Generates a PDF and sends it straight to the system print dialog.
    func printReport() {
        generatePDF { url in
            PrintHelper.printFile(at: url, jobName: "Sucro \(self.period.rawValue) Report")
        }
    }

    private func generatePDF(onSuccess: @escaping (URL) -> Void) {
        let range = currentRange
        let readings = dataService.fetchGlucoseReadings(context: viewContext, in: range)
        let insulin = dataService.fetchInsulinEntries(context: viewContext, in: range)
        let carbs = dataService.fetchCarbEntries(context: viewContext, in: range)

        guard !readings.isEmpty || !insulin.isEmpty || !carbs.isEmpty else {
            statusMessage = "No data available for this period yet."
            showStatusAlert = true
            return
        }

        isExporting = true
        exportService.exportToPDF(
            glucoseReadings: readings,
            insulinEntries: insulin,
            carbEntries: carbs,
            dateRange: range
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isExporting = false
                switch result {
                case .success(let url):
                    onSuccess(url)
                case .failure(let error):
                    self.statusMessage = error.localizedDescription
                    self.showStatusAlert = true
                }
            }
        }
    }
}
