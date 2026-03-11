//
//  ActivityEntry.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import Foundation
import CoreData

@objc(ActivityEntry)
public class ActivityEntry: NSManagedObject {
    
}

extension ActivityEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ActivityEntry> {
        return NSFetchRequest<ActivityEntry>(entityName: "ActivityEntry")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var duration: Int16
    @NSManaged public var intensity: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var notes: String?
    @NSManaged public var caloriesBurned: Double
}

extension ActivityEntry : Identifiable {
    
}
