//
//  LibraryViewModel.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 20.03.2023.
//

import Foundation
import RxRelay
import Differentiator

protocol LibraryViewModelProtocol: CollectableViewModelProtocol where T == SectionModel<String, PlaylistUIProtocol> {
    var saver: PlaylistSaverProtocol { get set }
    var router: LibraryPageRouterProtocol? { get }
    func fetchPlaylists()
    func didTapOnPlaylist(indexPath: IndexPath)
}

class LibraryViewModel: LibraryViewModelProtocol {
    
    var saver: PlaylistSaverProtocol
    
    var router: LibraryPageRouterProtocol?
    
    var uiModels: RxRelay.BehaviorRelay<[SectionModel<String, PlaylistUIProtocol>]> = BehaviorRelay(value: [SectionModel(model: "", items: [PlaylistUIProtocol]() )])
    
    @objc func fetchPlaylists() {
        do {
            try uiModels.accept([SectionModel(model: "", items: saver.fetchAllPlaylists())])
        } catch {
            errorHandler(error: error)
        }
    }
    
    func errorHandler(error: Error) {
        //
    }
    
    func didTapOnPlaylist(indexPath: IndexPath) {
        if let pl = uiModels.value[indexPath.section].items[indexPath.row] as? Playlist {
            router?.moveToPlaylist(playlistID: pl.id)
        }
    }
    
    init(saver: PlaylistSaverProtocol) {
        self.saver = saver
        fetchPlaylists()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(fetchPlaylists),
                                               name: NotificationCenterNames.updatedPlaylists,                                           object: nil)
    }
}
