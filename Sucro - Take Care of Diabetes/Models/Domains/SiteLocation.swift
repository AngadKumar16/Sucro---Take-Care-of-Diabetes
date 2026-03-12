//
//  SiteLocation.swift
//  Sucro - Take Care of Diabetes
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
    
    var iconName: String {
        switch self {
        case .abdomenLeft, .abdomenRight, .abdomenCenter:
            return "circle.fill"
        case .thighLeft, .thighRight:
            return "rectangle.fill"
        case .armLeft, .armRight:
            return "capsule.fill"
        case .buttocksLeft, .buttocksRight:
            return "oval.fill"
        case .other:
            return "questionmark.circle.fill"
        }
    }
    
    var bodyRegion: String {
        switch self {
        case .abdomenLeft, .abdomenRight, .abdomenCenter:
            return "Abdomen"
        case .thighLeft, .thighRight:
            return "Thigh"
        case .armLeft, .armRight:
            return "Arm"
        case .buttocksLeft, .buttocksRight:
            return "Buttocks"
        case .other:
            return "Other"
        }
    }
    
    var coordinates: (x: Double, y: Double) {
        switch self {
        case .abdomenLeft:
            return (0.3, 0.5)
        case .abdomenRight:
            return (0.7, 0.5)
        case .abdomenCenter:
            return (0.5, 0.5)
        case .thighLeft:
            return (0.3, 0.8)
        case .thighRight:
            return (0.7, 0.8)
        case .armLeft:
            return (0.2, 0.3)
        case .armRight:
            return (0.8, 0.3)
        case .buttocksLeft:
            return (0.3, 0.7)
        case .buttocksRight:
            return (0.7, 0.7)
        case .other:
            return (0.5, 0.5)
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

struct BodyMapPosition {
    let location: SiteLocation
    let isActive: Bool
    let lastUsed: Date?
    let notes: String?
    
    init(location: SiteLocation, isActive: Bool = false, lastUsed: Date? = nil, notes: String? = nil) {
        self.location = location
        self.isActive = isActive
        self.lastUsed = lastUsed
        self.notes = notes
    }
    
    var daysSinceLastUse: Int? {
        guard let lastUsed = lastUsed else { return nil }
        return Calendar.current.dateComponents([.day], from: lastUsed, to: Date()).day
    }
}
