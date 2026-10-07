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

    static let popular: [HelpArticle] = [
        HelpArticle(title: "Quick Logging in 30 Seconds", body: HelpSection.logging.content),
        HelpArticle(title: "Setting Up Your CGM", body: HelpSection.cgm.content),
        HelpArticle(title: "Understanding Time in Range", body: HelpSection.insights.content),
    ]

    static let faq: [HelpArticle] = [
        HelpArticle(
            title: "How do I export data?",
            body: "Open Reports, pick a time period, and tap Export as PDF. Share with Doctor sends the same PDF. To get your raw readings as a spreadsheet, use Export Data in Settings."
        ),
        HelpArticle(
            title: "What does Time in Range mean?",
            body: "It's the percentage of your readings that fall inside your target range. The default range is 70 to 180 mg/dL, and you can change it in Settings. Most people aim for 70% or more."
        ),
        HelpArticle(
            title: "How often should I change my site?",
            body: "Most infusion sites need changing every 2 to 3 days. When you log a site change, Sucro reminds you when the next one is due."
        ),
    ]
}
