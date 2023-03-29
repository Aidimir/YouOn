//
//  PlayerDataManager.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 29.03.2023.
//

import Foundation
import CoreData

protocol PlayerDataManagerProtocol: DataManagerProtocol {
    func fetchSavedData() throws -> PlayerInfo?
    func saveData(info: Codable) throws
}

class PlayerDataManager: DataManager, PlayerDataManagerProtocol {
    func fetchSavedData() throws -> PlayerInfo? {
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<PlayerInfoEntity> = PlayerInfoEntity.fetchRequest()
        
        var playerInfoEntity: PlayerInfoEntity? = nil
        
        do {
            playerInfoEntity = try fetchEntity()
            
            if let playerInfoEntity = playerInfoEntity {
                let info = convertDataToInfo(data: playerInfoEntity.jsonData)
                return info
            }
            
            return nil
        } catch {
            throw error
        }
        
    }
    
    func saveData(info: Codable) throws {
        let context = appDelegate.persistentContainer.viewContext
        
        do {
            let existingEntity = try fetchEntity()
            
            if existingEntity != nil {
                existingEntity?.jsonData = info.saveAsJsonData()
                try context.save()
            } else {
                guard let entity = NSEntityDescription.entity(forEntityName: "PlayerInfoEntity", in: context) else { return }
                
                let object = PlayerInfoEntity(entity: entity, insertInto: context)
                object.jsonData = info.saveAsJsonData()
                try context.save()
            }
        } catch {
            throw error
        }
    }
    
    private func fetchEntity() throws -> PlayerInfoEntity? {
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<PlayerInfoEntity> = PlayerInfoEntity.fetchRequest()
        
        do {
            let entity = try context.fetch(fetchRequest).first
            return entity
        } catch {
            throw error
        }
    }
    
    private func convertDataToInfo(data: Data?) -> PlayerInfo? {
        guard let data = data else { return nil }
        do {
            let result = try JSONDecoder().decode(PlayerInfo.self, from: data)
            return result
        } catch {
            return nil
        }
    }
}
