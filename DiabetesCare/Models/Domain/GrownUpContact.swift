//
//  GrownUpContact.swift
//  DiabetesCare
//
//  The person a kid or teen calls or texts from Get Help. Works without
//  iCloud: it just opens the Phone or Messages app.
//

import Foundation

nonisolated struct GrownUpContact: Equatable, Sendable {
    let name: String
    /// Digits, with a leading + kept for international numbers.
    let phone: String

    /// `nil` unless the number has at least 3 digits.
    init?(name: String, phone: String) {
        let trimmed = phone.trimmingCharacters(in: .whitespaces)
        let digits = trimmed.filter(\.isASCII).filter(\.isNumber)
        guard digits.count >= 3 else { return nil }
        self.phone = (trimmed.hasPrefix("+") ? "+" : "") + digits
        let name = name.trimmingCharacters(in: .whitespaces)
        self.name = name.isEmpty ? String(localized: "My Grown-Up") : name
    }

    var callURL: URL? { URL(string: "tel:\(phone)") }

    /// Opens Messages with the text filled in.
    func textURL(message: String) -> URL? {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=?+")
        let body = message.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        return URL(string: "sms:\(phone)&body=\(body)")
    }

    /// "I need help. My glucose is 64 mg/dL." The reading is left out when
    /// there isn't a recent one.
    static func helpMessage(glucose: String?) -> String {
        if let glucose {
            return String(localized: "I need help. My glucose is \(glucose). (Sent from DiabetesCare)")
        }
        return String(localized: "I need help. (Sent from DiabetesCare)")
    }
}
