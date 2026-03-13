//
//  DraftOperation.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import CoreData
import SwiftUI

// Generic drafting operation for any Core Data object - NOT an ObservableObject
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
    
    func save() {
        do {
            try tempContext.save()
            onSave()
        } catch {
            print("Error saving draft: \(error)")
        }
    }
    
    func cancel() {
        tempContext.rollback()
        onCancel()
    }
}

// View wrapper - use @StateObject or just pass it directly
struct DraftingView<Object: NSManagedObject, Content: View>: View {
    let operation: DraftOperation<Object>  // CHANGED: Removed @ObservedObject
    @Environment(\.dismiss) private var dismiss
    let content: (Object) -> Content
    
    init(operation: DraftOperation<Object>, @ViewBuilder content: @escaping (Object) -> Content) {
        self.operation = operation
        self.content = content
    }
    
    var body: some View {
        NavigationView {
            content(operation.draftObject)
                .environment(\.managedObjectContext, operation.tempContext)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            operation.cancel()
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            operation.save()
                            dismiss()
                        }
                    }
                }
        }
    }
}
