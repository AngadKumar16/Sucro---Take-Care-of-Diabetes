//
//  InsulinEntry.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import Foundation
import CoreData

@objc(InsulinEntry)
public class InsulinEntry: NSManagedObject {
    
}

extension InsulinEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<InsulinEntry> {
        return NSFetchRequest<InsulinEntry>(entityName: "InsulinEntry")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var units: Double
    @NSManaged public var type: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var deliveryMethod: String?
    @NSManaged public var notes: String?
    @NSManaged public var glucoseReading: GlucoseReading?
}

extension InsulinEntry : Identifiable {
    
}
