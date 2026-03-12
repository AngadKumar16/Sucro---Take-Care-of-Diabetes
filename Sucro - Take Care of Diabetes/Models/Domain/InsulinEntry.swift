//
//  InsulinEntry.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation
import CoreData

@objc(InsulinEntry)
public class InsulinEntry: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var units: Double
    @NSManaged public var type: String?
    @NSManaged public var notes: String?
}

extension InsulinEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<InsulinEntry> {
        return NSFetchRequest<InsulinEntry>(entityName: "InsulinEntry")
    }
}

extension InsulinEntry: Identifiable {
    nonisolated override public func awakeFromInsert() {
        super.awakeFromInsert()
        MainActor.assumeIsolated {
            self.id = UUID()
            self.timestamp = Date()
        }
    }
}