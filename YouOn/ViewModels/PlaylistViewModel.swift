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

protocol PlaylistViewModelDelegate: AnyObject {
    func asInfoFetched(_ isAddable: Bool)
}

protocol PlaylistViewModelProtocol: AnyObject, CollectableViewModelProtocol where T == MediaFileUIProtocol {
    var delegate: PlaylistViewModelDelegate? { get set }
    var router: LibraryPageRouterProtocol? { get set }
    var isAddable: Bool { get }
    var title: String? { get }
    var imgURL: BehaviorRelay<URL?> { get }
    func playSong(indexPath: IndexPath)
    func playVideo(indexPath: IndexPath)
    func removeFromPlaylist(indexPath: IndexPath)
    func removeFromAll(indexPath: IndexPath)
    func fetchActionModels(indexPath: IndexPath) -> [ActionModel]
    func saveStorage()
    func moveToAddFilesController()
    init(player: MusicPlayerProtocol, saver: PlaylistSaverProtocol?, id: UUID, playlist: Playlist?)
}

class PlaylistViewModel: PlaylistViewModelProtocol {
    
    var title: String? {
        get {
            return playlist?.title
        }
    }
    
    var imgURL: BehaviorRelay<URL?> = BehaviorRelay(value: nil)
    
    weak var delegate: PlaylistViewModelDelegate?
    
    var isAddable: Bool {
        get {
            if let isDefault = playlist?.isDefaultPlaylist {
                return !isDefault
            }
            return false
        }
    }
    
    weak var router: LibraryPageRouterProtocol?
    
    var uiModels: RxRelay.BehaviorRelay<[MediaFileUIProtocol]> = BehaviorRelay(value: [MediaFileUIProtocol]())
    
    weak var player: MusicPlayerProtocol?
    
    weak var saver: PlaylistSaverProtocol?
    
    private let id: UUID
    
    private var playlist: Playlist?
    
    private var allFilesStorage: [MediaFile]?
    
    required init(player: MusicPlayerProtocol, saver: PlaylistSaverProtocol?, id: UUID, playlist: Playlist?) {
        self.player = player
        self.saver = saver
        self.playlist = playlist
        self.id = id
        fetchData()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(fetchData),
                                               name: NotificationCenterNames.updatedPlaylists, object: nil)
    }
    
    @objc func fetchData() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            do {
                if let playlist = try self.saver?.fetchPlaylist(id: self.id) {
                    self.playlist = playlist
                    self.imgURL.accept(playlist.imageURL)
                    self.delegate?.asInfoFetched(self.isAddable)
                    self.uiModels.accept(playlist.content)
                }
            } catch {
                self.errorHandler(error)
            }
        }
    }
    
    func fetchActionModels(indexPath: IndexPath) -> [ActionModel] {
        var actions = [ActionModel]()
        
        if let item = uiModels.value[indexPath.row] as? MediaFile, item.supportsVideo {
            
            let playVideoAction = ActionModel(title: "Play video", onTap: {
                self.playVideo(indexPath: indexPath)
            }, iconName: "play.circle")
            actions.append(playVideoAction)
        }
            
        if let playlist = playlist, !playlist.isDefaultPlaylist {
            let removeAction = ActionModel(title: "Remove", onTap: {
                self.removeFromPlaylist(indexPath: indexPath)
            }, iconName: "trash")
            actions.append(removeAction)
        }
        
        let removeFromAllAction = ActionModel(title: "Delete from device", onTap: {
            self.removeFromAll(indexPath: indexPath)
        }, iconName: "minus")
        actions.append(removeFromAllAction)
        
        return actions
    }
    
    func playSong(indexPath: IndexPath) {
        if let mediaStorage = uiModels.value as? [MediaFile] {
            player?.storage = mediaStorage
            player?.play(index: indexPath.row)
        }
    }
    
    func playVideo(indexPath: IndexPath) {
        if let mediaFile = uiModels.value[indexPath.row] as? MediaFile, mediaFile.supportsVideo {
            DispatchQueue.main.async { [weak self] in
                self?.router?.moveToVideoPlayer(file: mediaFile)
            }
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
            removeFromAll(indexPath: indexPath)
        } else {
            uiModels.removeElement(at: indexPath.row)
        }
        
        saveStorage()
    }
    
    func removeFromAll(indexPath: IndexPath) {
        if let file = uiModels.value[indexPath.row] as? MediaFile {
            do {
                try saver?.removeFromAll(file: file)
                uiModels.removeElement(at: indexPath.row)
            } catch {
                errorHandler(error)
            }
        }
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
            }
        } catch {
            errorHandler(error)
        }
    }
    
    func errorHandler(_ error: Error) {
        router?.showAlert(title: "Media-file error", error: error, msgWithError: nil, action: nil)
    }
}
