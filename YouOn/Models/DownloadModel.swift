//
//  DownloadModel.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 30.03.2023.
//

import Foundation
import Differentiator
import RxSwift
import Alamofire

protocol DownloadModelUIProtocol {
    var identity: String { get set }
    var title: String { get set }
    var progress: Observable<CGFloat>? { get set }
}

struct DownloadModel: DownloadModelUIProtocol, IdentifiableType, Equatable {
    
    static func == (lhs: DownloadModel, rhs: DownloadModel) -> Bool {
        lhs.dataRequest == rhs.dataRequest
    }
    
    var identity: String
    var title: String
    var link: String
    var progress: Observable<CGFloat>?
    var dataRequest: DataRequest
}
