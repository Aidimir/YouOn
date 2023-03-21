//
//  VideoFounderViewModel.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 17.03.2023.
//

import Foundation

protocol ViewModelProtocol {
    func errorHandler(error: Error)
}

protocol VideoFounderViewModelDelegate {
    func downloadProgress(result: Double)
}

protocol VideoFounderViewModelProtocol: ViewModelProtocol {
    var searchFieldString: String { get set }
    var networkService: YTNetworkServiceProtocol { get set }
    var delegate: VideoFounderViewModelDelegate? { get set }
    var router: FounderRouterProtocol? { get set }
    func onSearchTap()
}

class VideoFounderViewModel: VideoFounderViewModelProtocol {
    
    var router: FounderRouterProtocol?
    
    var networkService: YTNetworkServiceProtocol
    
    public var searchFieldString: String = ""
    
    init(networkService: YTNetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    public var delegate: VideoFounderViewModelDelegate?
    
    public func onSearchTap() {
        YTNetworkService().downloadVideo(linkString: searchFieldString) { progress in
            self.delegate?.downloadProgress(result: progress)
        } errorHandler: { error in
            self.errorHandler(error: error)
        }

    }
    
    public func errorHandler(error: Error) {
        router?.showAlert(title: "Download error", error: error, msgWithError: nil, action: nil)
    }
}
