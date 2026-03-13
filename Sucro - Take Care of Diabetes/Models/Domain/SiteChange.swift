//
//  SiteChange.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation
import CoreData

@objc(SiteChange)
public class SiteChange: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var location: String?
    @NSManaged public var notes: String?
    @NSManaged public var deviceType: String?
    @NSManaged public var siteType: String?
    @NSManaged public var photo: Data?
    
    // Convert string location to SiteLocation enum
    var siteLocation: SiteLocation {
        get {
            return SiteLocation(rawValue: location ?? "other") ?? .other
        }
        set {
            location = newValue.rawValue
        }
    }
}

extension SiteChange {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SiteChange> {
        return NSFetchRequest<SiteChange>(entityName: "SiteChange")
    }
}

extension SiteChange: Identifiable {
    nonisolated override public func awakeFromInsert() {
        super.awakeFromInsert()
        MainActor.assumeIsolated {
            self.id = UUID()
            self.timestamp = Date()
            self.location = SiteLocation.abdomenCenter.rawValue
        }
    }
}
