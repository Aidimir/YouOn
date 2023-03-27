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

protocol PlaylistViewModelDelegate {
    func barItemIf(_ isAddable: Bool)
}

protocol PlaylistViewModelProtocol: CollectableViewModelProtocol where T == MediaFileUIProtocol {
    var delegate: PlaylistViewModelDelegate? { get set }
    var router: LibraryPageRouterProtocol? { get set }
    var title: String? { get }
    func playSong(indexPath: IndexPath)
    func removeFromPlaylist(indexPath: IndexPath)
    func saveStorage()
    func moveToAddFilesController()
    init(player: MusicPlayerProtocol, saver: PlaylistSaverProtocol?, id: UUID)
}

class PlaylistViewModel: PlaylistViewModelProtocol {
    
    var title: String? {
        get {
            return playlist?.title
        }
    }
    
    var delegate: PlaylistViewModelDelegate?
    
    private var isAddable: Bool {
        get {
            if let isDefault = playlist?.isDefaultPlaylist {
                return !isDefault
            }
            return false
        }
    }
    
    var router: LibraryPageRouterProtocol?
    
    var uiModels: RxRelay.BehaviorRelay<[MediaFileUIProtocol]> = BehaviorRelay(value: [MediaFileUIProtocol]())
    
    private var player: MusicPlayerProtocol
    
    private let saver: PlaylistSaverProtocol?
    
    private let id: UUID
    
    private var playlist: Playlist?
    
    private var allFilesStorage: [MediaFile]?
    
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
                    self.delegate?.barItemIf(self.isAddable)
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
            router?.openPlayer()
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
        NotificationCenter.default.post(name: NotificationCenterNames.updatedPlaylists, object: nil)
        
        saveStorage()
    }
    
    func moveToAddFilesController() {
        do {
            if let storage = try saver?.fetchAllMedia() {
                allFilesStorage = storage
                router?.moveToAddItemsToPlaylist(allFilesStorage!, saveAction: addItems(indexes:))
            }
        } catch {
            errorHandler(error)
        }
    }
    
    func addItems(indexes: [IndexPath]) {
        do {
            if let allFilesStorage = allFilesStorage, let playlist = playlist {
                indexes.forEach { index in
                    var item = allFilesStorage[index.item]
                    item.playlistSpecID = UUID()
                    self.playlist!.addFile(file: item)
                    uiModels.accept([item] + uiModels.value)
                }
                try saver?.savePlaylist(playlist: self.playlist!)
                NotificationCenter.default.post(name: NotificationCenterNames.updatedPlaylists, object: nil)
            }
        } catch {
            errorHandler(error)
        }
    }
    
    func errorHandler(_ error: Error) {
        router?.showAlert(title: "Media-file error", error: error, msgWithError: nil, action: nil)
    }
}
