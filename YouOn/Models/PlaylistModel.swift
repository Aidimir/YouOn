//
//  PlaylistModel.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 15.03.2023.
//

import Foundation
import Differentiator

protocol PlaylistUIProtocol {
    var id: UUID { get }
    var title: String { get set }
    var imageURL: URL? { get }
    var isDefaultPlaylist: Bool { get }
    var tracksCountString: String { get }
}

struct Playlist: Codable, PlaylistUIProtocol {
    var content: [MediaFile]
    var title: String
    var id: UUID
        
    var tracksCountString: String {
        get {
            if content.count == 0 {
                return "No tracks"
            } else {
                if content.count == 1 {
                    return "\(content.count) track"
                }
                return "\(content.count) tracks"
            }
        }
    }
    
    var imageURL: URL? {
        get {
            return content.first?.imageURL
        }
    }
        
    var isDefaultPlaylist: Bool {
        get {
            let str = UserDefaults.standard.string(forKey: UserDefaultKeys.defaultAllPlaylist)
            if str != nil {
                return id == UUID(uuidString: str!)
            } else {
                return false
            }
        }
    }
    
    mutating func addFile(file: MediaFile) {
        if isDefaultPlaylist {
            content.removeAll(where: { $0.id == file.id})
        }
        content = [file] + content
    }
    
    mutating func removeFileById(id: String) {
        content.removeAll(where: { $0.id == id })
    }
}

struct PlaylistUIModel: IdentifiableType, Equatable, PlaylistUIProtocol {
    var id: UUID
    
    var identity: UUID {
        get {
            return id
        }
    }
    
    typealias Identity = UUID
    
    var title: String
    var imageURL: URL?
    var isDefaultPlaylist: Bool
    var tracksCountString: String
    
    init(model: PlaylistUIProtocol) {
        self.id = model.id
        self.title = model.title
        self.imageURL = model.imageURL
        self.isDefaultPlaylist = model.isDefaultPlaylist
        self.tracksCountString = model.tracksCountString
    }
}
