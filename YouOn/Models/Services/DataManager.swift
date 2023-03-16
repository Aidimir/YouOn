//
//  DataManager.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 16.03.2023.
//

import Foundation
import CoreData

protocol DataManagerProtocol {
    var appDelegate: AppDelegate { get }
    func resetStorage() throws
    init(appDelegate: AppDelegate)
}

class DataManager: DataManagerProtocol {
    
    var appDelegate: AppDelegate
    
    final func resetStorage() throws {
        let storeContainer = appDelegate.persistentContainer.persistentStoreCoordinator
        
        for store in storeContainer.persistentStores {
            do {
                try storeContainer.destroyPersistentStore(
                    at: store.url!,
                    ofType: store.type,
                    options: nil
                )
            } catch {
                throw error
            }
        }
        
        appDelegate.persistentContainer = NSPersistentContainer(
            name: "YouOn"
        )
        
        appDelegate.persistentContainer.loadPersistentStores {
            (store, error) in
        }
    }
    
    required init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }
}
