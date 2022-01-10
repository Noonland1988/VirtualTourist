//
//  DataController.swift
//  VirtualTourist
//
//  Created by 嶋田省吾 on 2021/12/11.
//

import Foundation
import CoreData

class DataController {
    //Creating persistent container
    let persistentContainer: NSPersistentContainer
    
    //add convinience property to access the context
    var viewContext:NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init(modelName:String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    //load the persistent store
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            completion?()
        }
    }
    
    
}
