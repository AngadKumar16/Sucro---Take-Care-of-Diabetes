//
//  GlucoseReading.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation
import CoreData

@objc(GlucoseReading)
public class GlucoseReading: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var value: Double
    @NSManaged public var unit: String?
    @NSManaged public var trend: String?
    @NSManaged public var source: String?
}

extension GlucoseReading {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GlucoseReading> {
        return NSFetchRequest<GlucoseReading>(entityName: "GlucoseReading")
    }
}

extension GlucoseReading: Identifiable {
    nonisolated override public func awakeFromInsert() {
        super.awakeFromInsert()
        MainActor.assumeIsolated {
            self.id = UUID()
            self.timestamp = Date()
        }
    }
}