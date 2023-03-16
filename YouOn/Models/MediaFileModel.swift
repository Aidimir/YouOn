//
//  MediaFileModel.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 15.03.2023.
//

import Foundation

struct MediaFile: Codable {
    var url: String
    var title: String
    var id: String
    var duration: TimeInterval
    var author: String
    var videoURL: URL
    var supportsVideo: Bool = false
    var videoDescription: String?
    var imgURL: URL?
}
