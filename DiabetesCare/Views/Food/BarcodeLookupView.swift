//
//  BarcodeLookupView.swift
//  DiabetesCare
//
//  Scan a package (or type its barcode) and get the carbs from Open Food
//  Facts. Off until the person turns it on, because the barcode leaves the
//  phone. Nothing else is sent.
//

import SwiftUI
import Vision
import VisionKit

struct BarcodeLookupView: View {
    let onFound: (FoodItem) -> Void

    @Environment(SettingsStore.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var barcode = ""
    @State private var isLooking = false
    @State private var error: String?

    private var canScan: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    var body: some View {
        NavigationStack {
            Form {
                if !settings.barcodeLookupEnabled {
                    Section {
                        Toggle("Look Up Barcodes Online", isOn: Bindable(settings).barcodeLookupEnabled)
                            .accessibilityIdentifier("barcodeLookupToggle")
                    } footer: {
                        Text("Scanning sends only the barcode number to Open Food Facts, a free, open database of packaged foods. Nothing about you or your log is sent.")
                    }
                    .listRowBackground(Theme.card)
                } else {
                    if canScan {
                        Section {
                            BarcodeScanner { code in
                                guard !isLooking else { return }
                                barcode = code
                                Task { await lookUp() }
                            }
                            .frame(height: 260)
                            .listRowInsets(EdgeInsets())
                        } footer: {
                            Text("Point the camera at the barcode.")
                        }
                    }
                    Section {
                        HStack {
                            TextField("Barcode number", text: $barcode)
                                .keyboardType(.numberPad)
                                .accessibilityIdentifier("barcodeField")
                            if isLooking {
                                ProgressView()
                            } else {
                                Button("Look Up") { Task { await lookUp() } }
                                    .disabled(barcode.filter(\.isNumber).count < 6)
                                    .accessibilityIdentifier("barcodeLookUp")
                            }
                        }
                    } header: {
                        Text(canScan ? "Or type it" : "Barcode")
                    } footer: {
                        if let error {
                            Text(error).foregroundStyle(Theme.vermilion)
                        } else {
                            Text("Product data from Open Food Facts (ODbL).")
                        }
                    }
                    .listRowBackground(Theme.card)
                }
            }
            .instrumentBackground()
            .navigationTitle("Scan a Package")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func lookUp() async {
        isLooking = true
        error = nil
        defer { isLooking = false }
        do {
            let food = try await OpenFoodFacts.lookup(barcode: barcode)
            onFound(food)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

/// The live camera scanner, reporting the first barcode it recognizes.
private struct BarcodeScanner: UIViewControllerRepresentable {
    let onCode: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean13, .ean8, .upce, .code128])],
            qualityLevel: .balanced,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {}

    static func dismantleUIViewController(_ controller: DataScannerViewController, coordinator: Coordinator) {
        controller.stopScanning()
    }

    func makeCoordinator() -> Coordinator { Coordinator(onCode: onCode) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onCode: (String) -> Void
        init(onCode: @escaping (String) -> Void) { self.onCode = onCode }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                if case .barcode(let barcode) = item, let value = barcode.payloadStringValue {
                    onCode(value)
                    return
                }
            }
        }
    }
}
