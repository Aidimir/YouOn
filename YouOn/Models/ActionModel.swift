//
//  ActionModel.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 30.03.2023.
//

import Foundation

struct ActionModel {
    var title: String?
    var onTap: (() -> Void)?
    var iconName: String?
}
