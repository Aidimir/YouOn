//
//  MediaSaverService.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 16.03.2023.
//

import Foundation

protocol MediaSaverProtocol {
    var dataManager: MediaDataManagerProtocol { get set }
    func saveToAll(file: MediaFile) throws
    func removeFromAll(file: MediaFile) throws
    func savePlaylist(playlist: Playlist) throws
    func removePlaylist(playlist: Playlist) throws
}

class MediaSaver: MediaSaverProtocol {
    var dataManager: MediaDataManagerProtocol
    
    init(dataManager: MediaDataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    func saveToAll(file: MediaFile) throws {
        try dataManager.saveMedia(data: file, id: file.id)
    }
    
    func removeFromAll(file: MediaFile) throws {
        try dataManager.removeMedia(id: file.id)
    }
    
    func savePlaylist(playlist: Playlist) throws {
        try dataManager.savePlaylist(data: playlist, id: playlist.id)
    }
    
    func removePlaylist(playlist: Playlist) throws {
        try dataManager.removePlaylist(id: playlist.id)
    }
    
}
