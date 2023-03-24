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
    var isDeletable: Bool { get }
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
                return "\(content.count) tracks"
            }
        }
    }
    
    var imageURL: URL? {
        get {
            return content.last?.imageURL
        }
    }
        
    var isDeletable: Bool {
        get {
            let str = UserDefaults.standard.string(forKey: UserDefaultKeys.defaultAllPlaylist)
            if str != nil {
                return id != UUID(uuidString: str!)
            } else {
                return true
            }
        }
    }
    
    mutating func addFile(file: MediaFile) {
        content.removeAll(where: { $0.id == file.id})
        content.append(file)
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
    var isDeletable: Bool
    var tracksCountString: String
    
    init(model: PlaylistUIProtocol) {
        self.id = model.id
        self.title = model.title
        self.imageURL = model.imageURL
        self.isDeletable = model.isDeletable
        self.tracksCountString = model.tracksCountString
    }
}
