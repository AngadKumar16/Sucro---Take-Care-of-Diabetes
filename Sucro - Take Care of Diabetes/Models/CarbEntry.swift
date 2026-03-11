//
//  CarbEntry.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import Foundation
import CoreData

@objc(CarbEntry)
public class CarbEntry: NSManagedObject {
    
}

extension CarbEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CarbEntry> {
        return NSFetchRequest<CarbEntry>(entityName: "CarbEntry")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var grams: Double
    @NSManaged public var timestamp: Date?
    @NSManaged public var mealType: String?
    @NSManaged public var foodItems: String?
    @NSManaged public var notes: String?
    @NSManaged public var photo: Data?
}

extension CarbEntry : Identifiable {
    
}
