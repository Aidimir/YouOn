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
    var player: MusicPlayerProtocol { get }
    var saver: PlaylistSaverProtocol? { get }
    var router: RouterProtocol? { get set }
    var id: UUID { get set }
    func playSong(indexPath: IndexPath)
    func saveStorage()
}

class PlaylistViewModel: PlaylistViewModelProtocol {
    
    var router: RouterProtocol?
    
    var uiModels: RxRelay.BehaviorRelay<[MediaFileUIProtocol]> = BehaviorRelay(value: [MediaFileUIProtocol]())
    
    var player: MusicPlayerProtocol
    
    var saver: PlaylistSaverProtocol?
    
    var id: UUID
    
    private var playlist: Playlist?
    
    init(player: MusicPlayerProtocol, saver: PlaylistSaverProtocol?,
         router: RouterProtocol?, id: UUID) {
        self.player = player
        self.saver = saver
        self.router = router
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
                if let files = try self.saver?.fetchPlaylist(id: self.id)?.content {
                    self.uiModels.accept(files)
                }
            } catch {
                self.errorHandler(error: error)
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
                try saver?.savePlaylist(playlist: playlist!)
            } catch {
                errorHandler(error: error)
            }
        }
    }
    
    func errorHandler(error: Error) {
//        
    }
}
