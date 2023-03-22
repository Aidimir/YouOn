//
//  VideoFounderViewModel.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 17.03.2023.
//

import Foundation

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
        networkService.downloadVideo(linkString: searchFieldString, completion: { progress in
            self.delegate?.downloadProgress(result: progress)
        }, onCompleted: {
            NotificationCenter.default.post(name: NotificationCenterNames.updatedPlaylists, object: nil)
            
            if let allPlString = UserDefaults.standard.string(forKey: UserDefaultKeys.defaultAllPlaylist), let playlistId = UUID(uuidString: allPlString) {
                NotificationCenter.default.post(name: NotificationCenterNames.updatePlaylistWithID(id: playlistId), object: nil)
            }
        }, errorHandler: errorHandler(error:))
    }
    
    public func errorHandler(error: Error) {
        router?.showAlert(title: "Download error", error: error, msgWithError: nil, action: nil)
    }
}
