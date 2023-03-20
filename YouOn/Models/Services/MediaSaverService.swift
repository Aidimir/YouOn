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
    func fetchPlaylist(id: UUID) throws -> Playlist?
    func fetchAllPlaylists() throws -> [Playlist]
    func fetchAllMedia() throws -> [MediaFile]
}

class MediaSaver: MediaSaverProtocol {
    
    var dataManager: MediaDataManagerProtocol
    
    init(dataManager: MediaDataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    func saveToAll(file: MediaFile) throws {
        try dataManager.saveMedia(data: file, id: file.id)
        if UserDefaults.standard.string(forKey: UserDefaultKeys.defaultAllPlaylist) == nil {
            let id = UUID()
            let pl = Playlist(content: [MediaFile](), title: "All", id: id)
            UserDefaults.standard.setValue(id.uuidString, forKey: UserDefaultKeys.defaultAllPlaylist)
            try dataManager.savePlaylist(data: pl, id: id)
        } else {
            let idStr = UserDefaults.standard.string(forKey: UserDefaultKeys.defaultAllPlaylist)
            let id = UUID(uuidString: idStr!)!
            var playlist = try dataManager.fetchPlaylist(id: id)
            playlist?.addFile(file: file)
            try dataManager.savePlaylist(data: playlist, id: id)
        }
    }
    
    func removeFromAll(file: MediaFile) throws {
        try dataManager.removeMedia(id: file.id)
        if UserDefaults.standard.string(forKey: UserDefaultKeys.defaultAllPlaylist) != nil {
            let idStr = UserDefaults.standard.string(forKey: UserDefaultKeys.defaultAllPlaylist)
            let id = UUID(uuidString: idStr!)!
            var playlist = try dataManager.fetchPlaylist(id: id)
            playlist?.removeFileById(id: file.id)
            try dataManager.savePlaylist(data: playlist, id: id)
        }
    }
    
    func savePlaylist(playlist: Playlist) throws {
        try dataManager.savePlaylist(data: playlist, id: playlist.id)
    }
    
    func removePlaylist(playlist: Playlist) throws {
        try dataManager.removePlaylist(id: playlist.id)
    }
    
    func fetchPlaylist(id: UUID) throws -> Playlist? {
        try dataManager.fetchPlaylist(id: id)
    }
    
    func fetchAllPlaylists() throws -> [Playlist] {
        try dataManager.fetchAllPlaylists()
    }
    
    func fetchAllMedia() throws -> [MediaFile] {
        try dataManager.fetchAllMedia()
    }
}
