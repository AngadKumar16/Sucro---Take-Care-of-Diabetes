//
//  SiteLocation.swift
//  DiabetesCare
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation

enum SiteLocation: String, CaseIterable, Codable {
    case abdomenLeft = "Abdomen Left"
    case abdomenRight = "Abdomen Right"
    case abdomenCenter = "Abdomen Center"
    case thighLeft = "Thigh Left"
    case thighRight = "Thigh Right"
    case armLeft = "Arm Left"
    case armRight = "Arm Right"
    case buttocksLeft = "Buttocks Left"
    case buttocksRight = "Buttocks Right"
    case other = "Other"
    
    /// Reads a stored location, including the bare region names older edit
    /// screens saved ("abdomen", "arm", ...), which map to that region.
    init?(stored: String?) {
        guard let key = stored?.trimmingCharacters(in: .whitespaces).lowercased(), !key.isEmpty else {
            return nil
        }
        if let match = Self.allCases.first(where: { $0.rawValue.lowercased() == key }) {
            self = match
            return
        }
        switch key {
        case "abdomen": self = .abdomenCenter
        case "thigh": self = .thighLeft
        case "arm": self = .armLeft
        case "buttocks": self = .buttocksLeft
        default: return nil
        }
    }

    var rotationDays: Int {
        switch self {
        case .abdomenLeft, .abdomenRight, .abdomenCenter:
            return 2
        case .thighLeft, .thighRight:
            return 3
        case .armLeft, .armRight:
            return 4
        case .buttocksLeft, .buttocksRight:
            return 5
        case .other:
            return 3
        }
    }
}
