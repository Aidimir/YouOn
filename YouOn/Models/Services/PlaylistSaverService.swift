//
//  PlaylistSaverService.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 20.03.2023.
//

import Foundation

protocol PlaylistSaverProtocol: MediaSaverProtocol {
    func createPlaylist(title: String) throws -> UUID
    func removePlaylist(playlist: Playlist) throws
    func fetchPlaylist(id: UUID) throws -> Playlist?
    func savePlaylist(playlist: Playlist) throws
    func fetchAllPlaylists() throws -> [Playlist]
}

class PlaylistSaver: MediaSaver, PlaylistSaverProtocol {
    
    func createPlaylist(title: String) throws -> UUID {
        let id = UUID()
        let playlist = Playlist(content: [MediaFile](), title: title, id: id)
        try savePlaylist(playlist: playlist)
        return id
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
}
