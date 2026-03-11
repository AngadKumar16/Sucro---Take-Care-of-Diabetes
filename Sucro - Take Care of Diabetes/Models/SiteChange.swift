//
//  SiteChange.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import Foundation
import CoreData

@objc(SiteChange)
public class SiteChange: NSManagedObject {
    
}

extension SiteChange {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SiteChange> {
        return NSFetchRequest<SiteChange>(entityName: "SiteChange")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var siteType: String?
    @NSManaged public var location: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var notes: String?
    @NSManaged public var deviceType: String?
    @NSManaged public var photo: Data?
}

extension SiteChange : Identifiable {
    
}

extension SiteChange {
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        self.id = UUID()
        self.timestamp = Date()
        self.siteType = "infusion_set"
    }
}
