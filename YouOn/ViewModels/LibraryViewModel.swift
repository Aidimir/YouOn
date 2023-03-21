//
//  LibraryViewModel.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 20.03.2023.
//

import Foundation
import RxRelay

protocol LibraryViewModelProtocol: CollectableViewModelProtocol {
    var saver: PlaylistSaverProtocol { get set }
    var router: LibraryPageRouterProtocol? { get }
    func fetchPlaylists()
    func didTapOnPlaylist(indexPath: IndexPath)
}

class LibraryViewModel: LibraryViewModelProtocol {
    var saver: PlaylistSaverProtocol
    
    var router: LibraryPageRouterProtocol?
    
    var uiModels: RxRelay.BehaviorRelay<[PlaylistUIProtocol]> = BehaviorRelay(value: [PlaylistUIProtocol]())
    
    func fetchPlaylists() {
        do {
            try uiModels.accept(saver.fetchAllPlaylists())
        } catch {
            errorHandler(error: error)
        }
    }
    
    func errorHandler(error: Error) {
//
    }
    
    func didTapOnPlaylist(indexPath: IndexPath) {
        if let pl = uiModels.value[indexPath.row] as? Playlist {
            router?.moveToPlaylist(playlistID: pl.id)
        }
    }
    
    init(saver: PlaylistSaverProtocol) {
        self.saver = saver
    }
}
