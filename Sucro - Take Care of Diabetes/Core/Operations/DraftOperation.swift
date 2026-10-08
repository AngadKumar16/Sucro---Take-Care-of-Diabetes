//
//  DraftOperation.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import CoreData
import SwiftUI

// Generic drafting operation for any Core Data object.
class DraftOperation<Object: NSManagedObject>: Identifiable {
    let id = UUID()
    let tempContext: NSManagedObjectContext
    let draftObject: Object
    let isNew: Bool
    let onSave: () -> Void
    let onCancel: () -> Void
    
    init(
        withExistingObject object: Object,
        inParentContext parentContext: NSManagedObjectContext,
        onSave: @escaping () -> Void = {},
        onCancel: @escaping () -> Void = {}
    ) {
        self.isNew = false
        self.onSave = onSave
        self.onCancel = onCancel
        
        self.tempContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        self.tempContext.parent = parentContext
        self.draftObject = tempContext.object(with: object.objectID) as! Object
    }
    
    init(
        withParentContext parentContext: NSManagedObjectContext,
        createObject: (NSManagedObjectContext) -> Object,
        onSave: @escaping () -> Void = {},
        onCancel: @escaping () -> Void = {}
    ) {
        self.isNew = true
        self.onSave = onSave
        self.onCancel = onCancel
        
        self.tempContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        self.tempContext.parent = parentContext
        self.draftObject = createObject(tempContext)
    }
    
    /// Saves the draft through to the store. Returns false if that fails,
    /// leaving the draft as it was so the user can try again.
    @discardableResult
    func save() -> Bool {
        do {
            // Push the draft into the parent context...
            try tempContext.save()
            // ...then persist the parent to the store, otherwise edits only
            // live in memory and are lost when the app restarts.
            if let parent = tempContext.parent, parent.hasChanges {
                try parent.save()
            }
            onSave()
            return true
        } catch {
            print("Error saving draft: \(error)")
            return false
        }
    }

    func cancel() {
        tempContext.rollback()
        onCancel()
    }
}
