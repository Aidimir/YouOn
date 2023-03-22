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

protocol PlaylistViewModelProtocol: CollectableViewModelProtocol where T == SectionModel<String, MediaFileUIProtocol> {
    var player: MusicPlayerProtocol { get }
    var saver: PlaylistSaverProtocol? { get }
    var router: RouterProtocol? { get set }
    var id: UUID { get set }
    func playSong(indexPath: IndexPath)
    func saveStorage()
}

class PlaylistViewModel: PlaylistViewModelProtocol {
        
    var router: RouterProtocol?
    
    var uiModels: RxRelay.BehaviorRelay<[SectionModel<String, MediaFileUIProtocol>]> = BehaviorRelay(value: [SectionModel(model: "", items: [MediaFileUIProtocol]() )])

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
        do {
            if let mediaFiles = try saver?.fetchPlaylist(id: id)?.content {
                uiModels.accept([SectionModel(model: "", items: mediaFiles)])
            }
        } catch {
            errorHandler(error: error)
        }
    }
    
    func playSong(indexPath: IndexPath) {
        if let mediaStorage = uiModels.value[indexPath.section].items as? [MediaFile] {
            player.storage = mediaStorage
            player.play(index: indexPath.row)
        }
    }
    
    func saveStorage() {
        playlist?.content = uiModels.value.first?.items as! [MediaFile]
        do {
            try saver?.savePlaylist(playlist: playlist!)
        } catch {
            errorHandler(error: error)
        }
    }
    
    func errorHandler(error: Error) {
    }
}
