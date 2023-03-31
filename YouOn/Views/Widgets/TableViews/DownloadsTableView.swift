//
//  DownloadsTableView.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 30.03.2023.
//

import Foundation
import UIKit
import RxSwift
import Differentiator
import RxDataSources
import RxRelay
import RxCocoa

typealias DownloadsSectionModel = AnimatableSectionModel<String, DownloadModel>
