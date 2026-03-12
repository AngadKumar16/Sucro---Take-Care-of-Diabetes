//
//  DeviceStatus.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation
import CoreData

@objc(DeviceStatus)
public class DeviceStatus: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var deviceType: String?
    @NSManaged public var batteryLevel: Double
    @NSManaged public var lastSync: Date?
    @NSManaged public var connectionStatus: String?
    @NSManaged public var deviceName: String?
}

extension DeviceStatus {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DeviceStatus> {
        return NSFetchRequest<DeviceStatus>(entityName: "DeviceStatus")
    }
}

extension DeviceStatus: Identifiable {
    nonisolated override public func awakeFromInsert() {
        super.awakeFromInsert()
        MainActor.assumeIsolated {
            self.id = UUID()
            self.lastSync = Date()
        }
    }
}