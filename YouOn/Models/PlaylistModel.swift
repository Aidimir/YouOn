//
//  PlaylistModel.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 15.03.2023.
//

import Foundation

struct Playlist: Codable {
    var content: [MediaFile]
    var title: String
    var imageURL: URL?
    var id: UUID
    
    mutating func addFile(file: MediaFile) {
        content.append(file)
    }
    
    mutating func removeFileById(id: String) {
        content.removeAll(where: { $0.id == id })
    }
}
