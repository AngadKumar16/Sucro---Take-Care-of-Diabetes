//
//  GlucoseReading.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import Foundation
import CoreData

@objc(GlucoseReading)
public class GlucoseReading: NSManagedObject {
    
}

extension GlucoseReading {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GlucoseReading> {
        return NSFetchRequest<GlucoseReading>(entityName: "GlucoseReading")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var value: Double
    @NSManaged public var unit: String
    @NSManaged public var timestamp: Date?
    @NSManaged public var context: String?
    @NSManaged public var notes: String?
    @NSManaged public var source: String?
}

extension GlucoseReading : Identifiable {
    
}
