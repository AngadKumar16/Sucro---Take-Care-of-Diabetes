//
//  HelpArticle.swift
//  Sucro - Take Care of Diabetes
//

import Foundation

/// A short piece of help text shown on its own screen.
struct HelpArticle: Hashable, Identifiable {
    let title: String
    let body: String

    var id: String { title }

    static let faq: [HelpArticle] = [
        HelpArticle(
            title: "How do I export data?",
            body: "Open the Reports tab, pick a period, and tap Share PDF Report to send it by Mail, Messages or AirDrop. To get your glucose readings as a spreadsheet, use Export Glucose in Settings."
        ),
        HelpArticle(
            title: "What does Time in Range mean?",
            body: "It's the percentage of your readings that fall inside your target range. The default range is 70 to 180 mg/dL, and you can change it in Settings. Most people aim for 70% or more."
        ),
        HelpArticle(
            title: "How often should I change my site?",
            body: "Most infusion sites need changing every 2 to 3 days. When you log a site change, DiabetesCare reminds you when the next one is due."
        ),
    ]
}
