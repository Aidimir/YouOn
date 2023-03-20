//
//  PlaylistModel.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 15.03.2023.
//

import Foundation
import Differentiator

protocol PlaylistUIProtocol {
    var title: String { get set }
    var imageURL: URL? { get set }
    var isDeletable: Bool { get }
}

struct Playlist: Codable, PlaylistUIProtocol {
    var content: [MediaFile]
    var title: String
    var imageURL: URL?
    var id: UUID
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
        content.append(file)
    }
    
    mutating func removeFileById(id: String) {
        content.removeAll(where: { $0.id == id })
    }
}


struct SectionOfPlaylistUI: SectionModelType {
    init(original: SectionOfPlaylistUI, items: [Item]) {
        self.items = items
        self = original
    }
    
    typealias Item = PlaylistUIProtocol
    
    var header: String?
    var items: [Item]
}
