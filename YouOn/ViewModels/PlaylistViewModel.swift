//
//  PlaylistViewModel.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 17.03.2023.
//

import Foundation
import RxRelay
import Differentiator

protocol CollectableViewModelProtocol: ViewModelProtocol {
    associatedtype T
    
    var uiModels: BehaviorRelay<[T]> { get set }
}

protocol PlaylistViewModelProtocol: CollectableViewModelProtocol where T == MediaFileUIProtocol {
    var router: RouterProtocol? { get set }
    func playSong(indexPath: IndexPath)
    func removeFromPlaylist(indexPath: IndexPath)
    func saveStorage()
    init(player: MusicPlayerProtocol, saver: PlaylistSaverProtocol?, id: UUID)
}

class PlaylistViewModel: PlaylistViewModelProtocol {
    
    var router: RouterProtocol?
    
    var uiModels: RxRelay.BehaviorRelay<[MediaFileUIProtocol]> = BehaviorRelay(value: [MediaFileUIProtocol]())
    
    private var player: MusicPlayerProtocol
    
    private let saver: PlaylistSaverProtocol?
    
    private let id: UUID
    
    private var playlist: Playlist?
    
    required init(player: MusicPlayerProtocol, saver: PlaylistSaverProtocol?, id: UUID) {
        self.player = player
        self.saver = saver
        self.id = id
        fetchData()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(fetchData),
                                               name: NotificationCenterNames.updatePlaylistWithID(id: id),                                           object: nil)
    }
    
    @objc func fetchData() {
        DispatchQueue.main.async { [ weak self ] in
            guard let self = self else { return }
            do {
                if let playlist = try self.saver?.fetchPlaylist(id: self.id) {
                    self.playlist = playlist
                    self.uiModels.accept(playlist.content)
                }
            } catch {
                self.errorHandler(error)
            }
        }
    }
    
    func playSong(indexPath: IndexPath) {
        if let mediaStorage = uiModels.value as? [MediaFile] {
            player.storage = mediaStorage
            player.play(index: indexPath.row)
        }
    }
    
    func saveStorage() {
        if let content = uiModels.value as? [MediaFile] {
            playlist?.content = content
            do {
                if let playlist = playlist {
                    try saver?.savePlaylist(playlist: playlist)
                }
            } catch {
                errorHandler(error)
            }
        }
    }
    
    func removeFromPlaylist(indexPath: IndexPath) {
        if let defaultAllPlaylistId = UserDefaults.standard.string(forKey: UserDefaultKeys.defaultAllPlaylist), defaultAllPlaylistId == playlist?.id.uuidString {
            if let file = uiModels.value[indexPath.row] as? MediaFile {
                do {
                    try saver?.removeFromAll(file: file)
                    uiModels.removeElement(at: indexPath.row)
                } catch {
                    errorHandler(error)
                }
            }
        } else {
            uiModels.removeElement(at: indexPath.row)
        }
        
        saveStorage()
    }
    
    func errorHandler(_ error: Error) {
        router?.showAlert(title: "Media-file error", error: error, msgWithError: nil, action: nil)
    }
}
