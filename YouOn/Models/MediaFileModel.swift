//
//  MediaFileModel.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 15.03.2023.
//

import Foundation
import Differentiator

protocol MediaFileUIProtocol {
    var title: String { get set }
    var duration: TimeInterval { get set }
    var author: String { get set }
    var imageURL: URL? { get set }
}

struct MediaFile: Codable, MediaFileUIProtocol {
    var url: String
    var title: String
    var id: String
    var duration: TimeInterval
    var author: String
    var videoURL: URL
    var supportsVideo: Bool = false
    var videoDescription: String?
    var imageURL: URL?
}

struct SectionOfMediaFileUI: SectionModelType {
    init(original: SectionOfMediaFileUI, items: [Item]) {
        self.items = items
        self = original
    }
    
    typealias Item = MediaFileUIProtocol
    
    var header: String?
    var items: [Item]
}
