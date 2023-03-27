//
//  NotificationCenterNames.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 21.03.2023.
//

import Foundation

enum NotificationCenterNames {
    static let updatedPlaylists = NSNotification.Name("updatePlaylists")
    static let playedSong = NSNotification.Name("playedSong")
    static func updatePlaylistWithID(id: UUID) -> NSNotification.Name {
        return NSNotification.Name("updatePlaylist:\(id.uuidString)")
    }
}
