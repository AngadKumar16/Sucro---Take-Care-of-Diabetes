//
//  ActivityEntry.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation
import CoreData

@objc(ActivityEntry)
public class ActivityEntry: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var type: String?
    @NSManaged public var duration: Int16
    @NSManaged public var intensity: String?
    @NSManaged public var caloriesBurned: Double
    @NSManaged public var notes: String?
}

extension ActivityEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ActivityEntry> {
        return NSFetchRequest<ActivityEntry>(entityName: "ActivityEntry")
    }
}

extension ActivityEntry: Identifiable {
    nonisolated override public func awakeFromInsert() {
        super.awakeFromInsert()
        MainActor.assumeIsolated {
            self.id = UUID()
            self.timestamp = Date()
        }
    }
}