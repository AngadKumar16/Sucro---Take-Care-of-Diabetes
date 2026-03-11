//
//  BaseViewModel.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import Foundation
import CoreData
import Combine

@MainActor
class BaseViewModel: ObservableObject {
    internal let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    func save() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    func delete(_ object: NSManagedObject) {
        viewContext.delete(object)
        save()
    }
}
