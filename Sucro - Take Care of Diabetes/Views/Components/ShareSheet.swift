//
//  ShareSheet.swift
//  Sucro - Take Care of Diabetes
//
//  Lightweight wrappers around UIKit sharing and printing so SwiftUI
//  views can present exported files (PDF / CSV).
//

import SwiftUI
import UIKit

/// Presents a system share sheet for the given items (typically file URLs).
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// Helper for sending a file to the system print dialog.
enum PrintHelper {
    static func printFile(at url: URL, jobName: String = "Sucro Report") {
        guard UIPrintInteractionController.canPrint(url) else { return }
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = jobName

        let controller = UIPrintInteractionController.shared
        controller.printInfo = info
        controller.printingItem = url
        controller.present(animated: true, completionHandler: nil)
    }
}
