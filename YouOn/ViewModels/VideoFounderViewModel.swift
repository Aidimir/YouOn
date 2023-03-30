//
//  VideoFounderViewModel.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 17.03.2023.
//

import Foundation
import RxRelay
import RxSwift

protocol VideoFounderViewModelProtocol: ViewModelProtocol {
    var itemsOnDownloading: BehaviorRelay<[DownloadModel]> { get }
    var searchFieldString: BehaviorRelay<String> { get }
    var isValid: Observable<Bool> { get }
    var router: FounderRouterProtocol? { get set }
    var waitingToResponse: BehaviorRelay<Bool> { get }
    init(networkService: YTNetworkServiceProtocol)
    func onSearchTap()
    func cancelDownloading(downloadModel: DownloadModel)
}

class VideoFounderViewModel: VideoFounderViewModelProtocol {
    
    var isValid: RxSwift.Observable<Bool> {
        get {
            return searchFieldString.asObservable().map({ !$0.isEmpty && $0.count > 10  })
        }
    }
    
    var searchFieldString: RxRelay.BehaviorRelay<String> = BehaviorRelay(value: String())
    
    var itemsOnDownloading: RxRelay.BehaviorRelay<[DownloadModel]> {
        get {
            return networkService.nowInDownloading
        }
    }
    
    var isButtonEnabled: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    
    var waitingToResponse: BehaviorRelay<Bool> = BehaviorRelay(value: false)
            
    var router: FounderRouterProtocol?
    
    private let networkService: YTNetworkServiceProtocol
    
    required init(networkService: YTNetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    public func onSearchTap() {
        
        if let linkString = searchFieldString.value.getYoutubeID() {
            
            if itemsOnDownloading.value.contains(where: { $0.link == linkString }) {
                let errorTemp = NSError(domain: "This video is already downloading !", code: -1, userInfo: nil)
                errorHandler(errorTemp)
                return
            }
            
            waitingToResponse.accept(true)
            networkService.downloadVideo(linkString: linkString, onGotResponse: {
                self.waitingToResponse.accept(false)
            }, onCompleted: {
                NotificationCenter.default.post(name: NotificationCenterNames.updatedPlaylists, object: nil)
                
                if let allPlString = UserDefaults.standard.string(forKey: UserDefaultKeys.defaultAllPlaylist), let playlistId = UUID(uuidString: allPlString) {
                    NotificationCenter.default.post(name: NotificationCenterNames.updatePlaylistWithID(id: playlistId), object: nil)
                }
            }, errorHandler: errorHandler(_:))
        }
    }
    
    func cancelDownloading(downloadModel: DownloadModel) {
        networkService.modelToStopDownloading.accept(downloadModel)
    }
    
    public func errorHandler(_ error: Error) -> Void {
        router?.showAlert(title: "Download error", error: error, msgWithError: nil, action: nil)
    }
}
