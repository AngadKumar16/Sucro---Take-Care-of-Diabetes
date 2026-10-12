//
//  BaseViewModel.swift
//  DiabetesCare
//
//  Created by Angad Kumar on 3/11/26.
//

import Foundation
import OSLog
import CoreData

/// Shared Core Data plumbing for the view models. Subclasses are
/// `@Observable`; this base holds nothing the UI watches.
@MainActor
class BaseViewModel {
    internal let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    /// Saves the view context. On failure the changes are kept in memory
    /// so the caller can say so and the user can try again.
    @discardableResult
    func save() -> Bool {
        do {
            try viewContext.save()
            return true
        } catch {
            Log.data.error("Error saving context: \(String(describing: error), privacy: .public)")
            return false
        }
    }
    
    func delete(_ object: NSManagedObject) {
        viewContext.delete(object)
        save()
    }
}
