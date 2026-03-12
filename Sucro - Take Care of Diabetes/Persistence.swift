//
//  Persistence.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample glucose readings for preview
        for i in 0..<10 {
            let reading = GlucoseReading(context: viewContext)
            reading.id = UUID()
            reading.timestamp = Date().addingTimeInterval(Double(-i * 3600)) // Hours ago
            reading.value = Double.random(in: 70...180)
            reading.unit = "mg/dL"
            reading.context = i % 2 == 0 ? "pre_meal" : "post_meal"
            reading.notes = "Sample reading \(i)"
        }
        
        // Add sample carb entry
        let carbEntry = CarbEntry(context: viewContext)
        carbEntry.id = UUID()
        carbEntry.timestamp = Date()
        carbEntry.grams = 45.0
        carbEntry.mealType = "lunch"
        carbEntry.foodItems = "Rice, Chicken, Vegetables"
        carbEntry.notes = "Sample meal"
        
        // Add sample insulin entry
        let insulinEntry = InsulinEntry(context: viewContext)
        insulinEntry.id = UUID()
        insulinEntry.timestamp = Date()
        insulinEntry.units = 5.0
        insulinEntry.type = "bolus"
        insulinEntry.deliveryMethod = "pen"
        insulinEntry.notes = "Sample dose"
        
        // Add sample activity entry
        let activityEntry = ActivityEntry(context: viewContext)
        activityEntry.id = UUID()
        activityEntry.timestamp = Date()
        activityEntry.type = "Walking"
        activityEntry.duration = 30
        activityEntry.intensity = "moderate"
        activityEntry.caloriesBurned = 150.0
        activityEntry.notes = "Sample activity"
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SucroDataModel")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
