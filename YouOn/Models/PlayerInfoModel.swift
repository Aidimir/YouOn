//
//  PlayerInfoModel.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 30.03.2023.
//

import Foundation

struct PlayerInfo: Codable {
    var storage: [MediaFile]
    var currentIndex: Int
    var currentTime: Double
    var duration: Double
}
