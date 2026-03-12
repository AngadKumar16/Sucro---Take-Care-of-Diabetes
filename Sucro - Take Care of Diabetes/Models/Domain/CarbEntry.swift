//
//  CarbEntry.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation
import CoreData

@objc(CarbEntry)
public class CarbEntry: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var grams: Double
    @NSManaged public var mealType: String?
    @NSManaged public var foodItems: String?
    @NSManaged public var notes: String?
}

extension CarbEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CarbEntry> {
        return NSFetchRequest<CarbEntry>(entityName: "CarbEntry")
    }
}

extension CarbEntry: Identifiable {
    nonisolated override public func awakeFromInsert() {
        super.awakeFromInsert()
        MainActor.assumeIsolated {
            self.id = UUID()
            self.timestamp = Date()
        }
    }
}