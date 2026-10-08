//
//  AppInfo.swift
//  Sucro - Take Care of Diabetes
//

import Foundation

/// App-wide constants shown to the user.
enum AppInfo {
    static let name = "DiabetesCare"
    static let supportEmail = "support@sucroapp.com"

    /// "1.0 (12)", read from the bundle so it can't drift from the build.
    static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    /// A mailto link with the version filled in, for support requests.
    static var supportEmailURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "\(name) Support Request"),
            URLQueryItem(name: "body", value: "Describe your issue here.\n\n---\nApp Version: \(version)"),
        ]
        return components.url
    }
}
