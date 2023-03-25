//
//  LibraryViewModel.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 20.03.2023.
//

import Foundation
import RxRelay
import Differentiator

protocol LibraryViewModelProtocol: CollectableViewModelProtocol where T == PlaylistUIProtocol {
    var router: LibraryPageRouterProtocol? { get set }
    func fetchPlaylists()
    func didTapOnPlaylist(indexPath: IndexPath)
    init(saver: PlaylistSaverProtocol)
}

class LibraryViewModel: LibraryViewModelProtocol {
    
    private let saver: PlaylistSaverProtocol
    
    var router: LibraryPageRouterProtocol?
    
    var uiModels: RxRelay.BehaviorRelay<[PlaylistUIProtocol]> = BehaviorRelay(value: [PlaylistUIProtocol]())
    
    @objc func fetchPlaylists() {
        DispatchQueue.main.async { [ weak self ] in
            guard let self = self else { return }
            do {
                try self.uiModels.accept(self.saver.fetchAllPlaylists())
            } catch {
                self.errorHandler(error)
            }
        }
    }
    
    func errorHandler(_ error: Error) {
        router?.showAlert(title: "Library error", error: error, msgWithError: nil, action: nil)
    }
    
    func didTapOnPlaylist(indexPath: IndexPath) {
        if let pl = uiModels.value[indexPath.row] as? Playlist {
            router?.moveToPlaylist(playlistID: pl.id)
        }
    }
    
    required init(saver: PlaylistSaverProtocol) {
        self.saver = saver
        fetchPlaylists()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(fetchPlaylists),
                                               name: NotificationCenterNames.updatedPlaylists,                                           object: nil)
    }
}
