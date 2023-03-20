//
//  PlaylistViewModel.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 17.03.2023.
//

import Foundation
import RxRelay

protocol CollectableViewModelProtocol {
    associatedtype T
    
    var uiModels: BehaviorRelay<[T]> { get set }
}

protocol PlaylistViewModelProtocol: ViewModelProtocol, CollectableViewModelProtocol {
    var player: MusicPlayerProtocol { get }
    var saver: MediaSaverProtocol { get }
    var router: RouterProtocol { get }
    func playSong(indexPath: IndexPath)
}

class PlaylistViewModel: PlaylistViewModelProtocol {
    
    var router: RouterProtocol
    
    var uiModels: RxRelay.BehaviorRelay<[MediaFileUIProtocol]> = BehaviorRelay(value: [MediaFileUIProtocol]())
        
    var player: MusicPlayerProtocol
    
    var saver: MediaSaverProtocol
    
    private var playlist: Playlist
    
    init(player: MusicPlayerProtocol, saver: MediaSaverProtocol, router: RouterProtocol, playlist: Playlist) {
        self.player = player
        self.saver = saver
        self.router = router
        self.playlist = playlist
    }
    
    func fetchData() {
        do {
            try uiModels.accept(saver.fetchAllMedia())
        } catch {
            errorHandler(error: error)
        }
    }
    
    func playSong(indexPath: IndexPath) {
        var curIndex = indexPath.row
        player.play(file: uiModels.value[indexPath.row]) {
            curIndex = IndexPath(index: indexPath.row + 1)
            if curIndex != uiModels.value.endIndex {
                playSong(indexPath: curIndex)
            } else { return }
        }
    }
    
    func errorHandler(error: Error) {
//
    }
}
