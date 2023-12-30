//
//  DataController.swift
//  VirtualTourist
//
//  Created by admin on 12/21/20.
//  Copyright © 2020 Com.JeremyKievit. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func load(completion: (() -> Void)? = nil) {
        // Load persistent stores for the DataController's persistent container
        
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            completion?() // Invoke the completion closure if provided
        }
    }
}


