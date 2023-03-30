//
//  DownloadModel.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 30.03.2023.
//

import Foundation
import Differentiator
import RxSwift

struct DownloadModel: IdentifiableType, Equatable {
    
    static func == (lhs: DownloadModel, rhs: DownloadModel) -> Bool {
        lhs.identity == rhs.identity
    }
    
    var identity: String
    var title: String
    var link: String
    var progress: Observable<CGFloat>
}
