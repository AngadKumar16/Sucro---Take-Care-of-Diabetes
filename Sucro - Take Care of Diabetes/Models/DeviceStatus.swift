//
//  DeviceStatus.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import Foundation
import CoreData

@objc(DeviceStatus)
public class DeviceStatus: NSManagedObject {
    
}

extension DeviceStatus {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DeviceStatus> {
        return NSFetchRequest<DeviceStatus>(entityName: "DeviceStatus")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var deviceType: String?
    @NSManaged public var deviceName: String?
    @NSManaged public var batteryLevel: Double
    @NSManaged public var lastSync: Date?
    @NSManaged public var isConnected: Bool
    @NSManaged public var firmwareVersion: String?
    @NSManaged public var serialNumber: String?
}

extension DeviceStatus : Identifiable {
    
}
