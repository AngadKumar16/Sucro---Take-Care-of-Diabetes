//
//  GlossaryTerm.swift
//  Sucro - Take Care of Diabetes
//

import Foundation

/// One entry in the glossary (`Resources/Glossary.json`).
nonisolated struct GlossaryTerm: Codable, Hashable, Identifiable, Sendable {
    /// Stable slug, used for links between terms and for saved terms.
    let id: String
    let name: String
    /// Other names and abbreviations people search for ("IOB", "Hypo").
    var aliases: [String] = []
    let category: GlossaryCategory
    /// One plain-language sentence.
    let summary: String
    /// A short paragraph with more context.
    let details: String
    /// Ids of related terms.
    var related: [String] = []
    /// Where the term shows up in DiabetesCare, if it does.
    var inApp: String?

    private enum CodingKeys: String, CodingKey {
        case id, name, aliases, category, summary, details, related, inApp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        aliases = try container.decodeIfPresent([String].self, forKey: .aliases) ?? []
        category = try container.decode(GlossaryCategory.self, forKey: .category)
        summary = try container.decode(String.self, forKey: .summary)
        details = try container.decode(String.self, forKey: .details)
        related = try container.decodeIfPresent([String].self, forKey: .related) ?? []
        inApp = try container.decodeIfPresent(String.self, forKey: .inApp)
    }

    /// The letter the term is filed under in the A–Z list.
    var indexLetter: String {
        guard let first = name.first, first.isLetter else { return "#" }
        return String(first).uppercased()
    }

    /// Keeps units like "mg/dL" from breaking across lines at the slash.
    static func unbreakable(_ text: String) -> String {
        text.replacingOccurrences(of: "mg/dL", with: "mg/\u{2060}dL")
            .replacingOccurrences(of: "mmol/L", with: "mmol/\u{2060}L")
    }

    /// Text for the share sheet.
    var shareText: String {
        "\(name)\n\n\(summary)\n\n\(details)"
    }
}
