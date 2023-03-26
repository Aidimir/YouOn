//
//  MediaFileModel.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 15.03.2023.
//

import Foundation
import Differentiator

protocol MediaFileUIProtocol: Any {
    var id: String { get }
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

struct MediaFileUIModel: IdentifiableType, Equatable, MediaFileUIProtocol {
    var id: String
    var title: String
    var duration: TimeInterval
    var author: String
    var imageURL: URL?
    
    var identity: String {
        get {
            return UUID().uuidString
        }
    }
    
    init(model: MediaFileUIProtocol) {
        self.id = model.id
        self.title = model.title
        self.imageURL = model.imageURL
        self.duration = model.duration
        self.author = model.author
    }
}
