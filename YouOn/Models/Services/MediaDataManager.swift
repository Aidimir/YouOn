//
//  MediaDataManager.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 16.03.2023.
//

import Foundation
import CoreData

protocol MediaDataManagerProtocol: DataManagerProtocol {
    func saveMedia(data: Codable, id: String) throws
    func savePlaylist(data: Codable, id: UUID) throws
    func removeMedia(id: String) throws
    func removePlaylist(id: UUID) throws
    func fetchMedia(id: String) throws -> MediaFile?
    func fetchPlaylist(id: UUID) throws -> Playlist?
    func fetchAllPlaylists() throws -> [Playlist]
    func fetchAllMedia() throws -> [MediaFile]
}

class MediaDataManager: DataManager, MediaDataManagerProtocol {
    private func convertDataToMedia(data: Data?) -> MediaFile? {
        guard let data = data else { return nil }
        do {
            let result = try JSONDecoder().decode(MediaFile.self, from: data)
            return result
        } catch {
            return nil
        }
    }
    
    private func convertDataToPlaylist(data: Data?) -> Playlist? {
        guard let data = data else { return nil }
        do {
            let result = try JSONDecoder().decode(Playlist.self, from: data)
            return result
        } catch {
            return nil
        }
    }
    
    func fetchMedia(id: String) throws -> MediaFile? {
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "id == %@", id
        )
        
        var mediaEntity: MediaEntity? = nil
        
        do {
            mediaEntity = try context.fetch(fetchRequest).first
            
            if let mediaEntity = mediaEntity {
                let media = convertDataToMedia(data: mediaEntity.file)
                return media
            }
            
            return nil
        } catch {
            throw error
        }
    }
    
    func fetchPlaylist(id: UUID) throws -> Playlist? {
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "id == %@", id.uuidString
        )
        
        var playlistEntity: PlaylistEntity? = nil
        
        do {
            playlistEntity = try context.fetch(fetchRequest).first
            
            if let playlistEntity = playlistEntity {
                var playlist = convertDataToPlaylist(data: playlistEntity.playlistData)
                try removeNotValid(playlist: &playlist!)
                return playlist
            }
            
            return nil
        } catch {
            throw error
        }
    }
    
    func fetchAllPlaylists() throws -> [Playlist] {
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
        var playlistEntities: [PlaylistEntity]? = nil
        
        do {
            playlistEntities = try context.fetch(fetchRequest)
            
            if let playlistEntities = playlistEntities {
                var res = [Playlist]()
                try playlistEntities.forEach { entity in
                    if entity.playlistData != nil {
                        if var converted = convertDataToPlaylist(data: entity.playlistData!) {
                            try removeNotValid(playlist: &converted)
                            res.append(converted)
                        }
                    }
                }
                
                return res
            }
        } catch {
            throw error
        }
        return [Playlist]()
    }
    
    func fetchAllMedia() throws -> [MediaFile] {
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
        var mediaEntities: [MediaEntity]? = nil
        
        do {
            mediaEntities = try context.fetch(fetchRequest)
            
            if let mediaEntities = mediaEntities {
                var content = [MediaFile]()
                mediaEntities.forEach { entity in
                    if entity.file != nil {
                        if let converted = convertDataToMedia(data: entity.file!) {
                            content.append(converted)
                        }
                    }
                }
                                
                return content
            }
        } catch {
            throw error
        }
        return [MediaFile]()
    }
    
    func saveMedia(data: Codable, id: String) throws {
        let context = appDelegate.persistentContainer.viewContext
        
        do {
            let existingEntity = try fetchMediaEntity(id: id)
            
            if existingEntity != nil {
                existingEntity?.file = data.saveAsJsonData()
                try context.save()
            } else {
                guard let entity = NSEntityDescription.entity(forEntityName: "MediaEntity", in: context) else { return }
                
                let object = MediaEntity(entity: entity, insertInto: context)
                object.file = data.saveAsJsonData()
                object.id = id
                try context.save()
            }
        } catch {
            throw error
        }
    }
    
    func savePlaylist(data: Codable, id: UUID) throws {
        let context = appDelegate.persistentContainer.viewContext
        
        do {
            let existingEntity = try fetchPlaylistEntity(id: id)
            
            if existingEntity != nil {
                if var pl = data as? Playlist {
                    try removeNotValid(playlist: &pl)
                    existingEntity?.playlistData = pl.saveAsJsonData()
                }
                
                existingEntity?.playlistData = data.saveAsJsonData()
                try context.save()
            } else {
                guard let entity = NSEntityDescription.entity(forEntityName: "PlaylistEntity", in: context) else { return }
                
                let object = PlaylistEntity(entity: entity, insertInto: context)
                object.playlistData = data.saveAsJsonData()
                object.id = id
                try context.save()
            }
        } catch {
            throw error
        }
    }
    
    func removeMedia(id: String) throws {
        let fetchRequest: NSFetchRequest<MediaEntity>
        fetchRequest = MediaEntity.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(
            format: "id == %@", id
        )
        fetchRequest.includesPropertyValues = false
        
        let context = appDelegate.persistentContainer.viewContext
        
        do {
            let object = try context.fetch(fetchRequest).first
            
            if object != nil {
                context.delete(object!)
                try context.save()
            }
        } catch {
            throw error
        }
    }
    
    func removePlaylist(id: UUID) throws {
        let fetchRequest: NSFetchRequest<PlaylistEntity>
        fetchRequest = PlaylistEntity.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(
            format: "id == %@", id.uuidString
        )
        fetchRequest.includesPropertyValues = false
        
        let context = appDelegate.persistentContainer.viewContext
        
        do {
            let object = try context.fetch(fetchRequest).first
            
            if object != nil {
                context.delete(object!)
                try context.save()
            }
        } catch {
            throw error
        }
    }
    
    private func fetchMediaEntity(id: String) throws -> MediaEntity? {
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "id == %@", id
        )
        
        do {
            let entity = try context.fetch(fetchRequest).first
            return entity
        } catch {
            throw error
        }
    }
    
    private func fetchPlaylistEntity(id: UUID) throws -> PlaylistEntity? {
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "id == %@", id.uuidString
        )
        
        do {
            let entity = try context.fetch(fetchRequest).first
            return entity
        } catch {
            throw error
        }
    }
}

extension MediaDataManager {
    private func removeNotValid(playlist: inout Playlist) throws {
        for i in playlist.content {
            if try fetchMedia(id: i.id) == nil {
                playlist.removeFileById(id: i.id)
            }
        }
    }
}
