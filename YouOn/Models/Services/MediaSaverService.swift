//
//  MediaSaverService.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 16.03.2023.
//

import Foundation

protocol MediaSaverProtocol: AnyObject {
    func saveToAll(file: MediaFile) throws
    func removeFromAll(file: MediaFile) throws
    func fetchAllMedia() throws -> [MediaFile]
    init(dataManager: MediaDataManagerProtocol, fileManager: FileManager)
}

class MediaSaver: MediaSaverProtocol {
    
    let dataManager: MediaDataManagerProtocol
    
    let fileManager: FileManager
    
    required init(dataManager: MediaDataManagerProtocol, fileManager: FileManager) {
        self.dataManager = dataManager
        self.fileManager = fileManager
    }
    
    func saveToAll(file: MediaFile) throws {
        try dataManager.saveMedia(data: file, id: file.id)
        if UserDefaults.standard.string(forKey: UserDefaultKeys.defaultAllPlaylist) == nil {
            let id = UUID()
            let pl = Playlist(content: [file], title: "All", id: id)
            UserDefaults.standard.setValue(id.uuidString, forKey: UserDefaultKeys.defaultAllPlaylist)
            try dataManager.savePlaylist(data: pl, id: id)
        } else {
            let idStr = UserDefaults.standard.string(forKey: UserDefaultKeys.defaultAllPlaylist)
            let id = UUID(uuidString: idStr!)!
            var playlist = try dataManager.fetchPlaylist(id: id)
            playlist?.addFile(file: file)
            try dataManager.savePlaylist(data: playlist, id: id)
        }
        NotificationCenter.default.post(name: NotificationCenterNames.updatedPlaylists, object: nil)
    }
    
    func removeFromAll(file: MediaFile) throws {
        try dataManager.removeMedia(id: file.id)
        if UserDefaults.standard.string(forKey: UserDefaultKeys.defaultAllPlaylist) != nil {
            var allPlaylists = try dataManager.fetchAllPlaylists()
            
            if let url = fileManager.urls(for: .documentDirectory, in: .allDomainsMask).first?.appendingPathComponent(file.url) {
                try fileManager.removeItem(at: url)
            }
            
            try allPlaylists.forEach { pl in
                var playlist = pl
                playlist.removeFileById(id: file.id)
                try dataManager.savePlaylist(data: playlist, id: playlist.id)
            }
            NotificationCenter.default.post(name: NotificationCenterNames.updatedPlaylists, object: nil)
        }
    }
    
    func fetchAllMedia() throws -> [MediaFile] {
        try dataManager.fetchAllMedia()
    }
}
