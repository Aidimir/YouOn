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
    var delegate: LibraryViewProtocol? { get set }
    func fetchPlaylists()
    func onAddPlaylistTapped()
    func onRenamePLaylistTapped(indexPath: IndexPath)
    func fetchActionModels(indexPath: IndexPath) -> [ActionModel]
    func didTapOnPlaylist(indexPath: IndexPath)
    func changePlaylistTitle(indexPath: IndexPath, title: String)
    func addPlaylist(_ text: String)
    func removePlaylist(indexPath: IndexPath)
    func saveAllPlaylists()
    init(saver: PlaylistSaverProtocol)
}

class LibraryViewModel: LibraryViewModelProtocol {
    
    private let saver: PlaylistSaverProtocol
    
    var delegate: LibraryViewProtocol?
    
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
    
    func addPlaylist(_ text: String) {
        do {
            let result = try saver.createPlaylist(title: text)
            fetchPlaylists()
        } catch {
            errorHandler(error)
        }
    }
    
    func fetchActionModels(indexPath: IndexPath) -> [ActionModel] {
        let renameAction = ActionModel(title: "Rename", onTap: {
            self.onRenamePLaylistTapped(indexPath: indexPath)
        }, iconName: "play.circle")
        
        let removeAction = ActionModel(title: "Remove", onTap: {
            self.removePlaylist(indexPath: indexPath)
        }, iconName: "trash")
        
        return [renameAction, removeAction]
    }
    
    func saveAllPlaylists() {
        do {
            if let playlists = uiModels.value as? [Playlist] {
                try playlists.forEach { pl in
                    try saver.savePlaylist(playlist: pl)
                }
            }
        } catch {
            errorHandler(error)
        }
    }
    
    func removePlaylist(indexPath: IndexPath) {
        do {
            if let playlist = uiModels.value[indexPath.row] as? Playlist {
                try saver.removePlaylist(playlist: playlist)
                uiModels.removeElement(at: indexPath.row)
            }
        } catch {
            errorHandler(error)
        }
    }
    
    func onAddPlaylistTapped() {
    }
    
    func onRenamePLaylistTapped(indexPath: IndexPath) {
        if let playlist = uiModels.value[indexPath.row] as? Playlist {
            DispatchQueue.main.async {
                self.delegate?.onPlaylistRenameTapped(indexPath: indexPath)
            }
        }
    }
    
    func changePlaylistTitle(indexPath: IndexPath, title: String) {
        do {
            if var playlist = uiModels.value[indexPath.row] as? Playlist, !playlist.isDefaultPlaylist {
                playlist.title = title
                try saver.savePlaylist(playlist: playlist)
            }
        } catch {
            errorHandler(error)
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
