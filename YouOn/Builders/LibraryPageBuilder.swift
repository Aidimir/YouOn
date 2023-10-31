//
//  LibraryPageBuilder.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 20.03.2023.
//

import Foundation
import UIKit
import AVKit

protocol LibraryPageBuilderProtocol: BuilderProtocol {
    func buildVideoPlayer(item: MediaFile) -> AVPlayerViewController?
    func buildLibraryViewController() -> UIViewController
    func buildPlaylistController(playlistID: UUID, playlist: Playlist?) -> UIViewController
    func buildAddItemsToPlaylist(_ fromStorage: [MediaFile], saveAction: (([IndexPath]) -> Void)?) -> UIViewController
}

class LibraryPageBuilder: NSObject, LibraryPageBuilderProtocol, AVPlayerViewControllerDelegate {
    
    func buildVideoPlayer(item: MediaFile) -> AVPlayerViewController? {
        guard let url = fileManager.urls(for: .documentDirectory, in: .allDomainsMask).first?.appendingPathComponent(item.url) else { return nil }
        let playerItem = AVPlayerItem(url: url)
        videoPlayer.replaceCurrentItem(with: playerItem)
        videoController.player = videoPlayer
        return videoController
    }
    
    private var player: MusicPlayer = MusicPlayer.shared
    
    private var playlistViewModel: PlaylistViewModel?
    
    private lazy var videoPlayer: AVPlayer = AVPlayer()
    
    private lazy var videoController: AVPlayerViewController = {
        var controller = AVPlayerViewController()
        controller.delegate = self
        return controller
    }()
    
    private let fileManager = FileManager.default
    
    private var router: LibraryPageRouter?
    
    private lazy var playlistSaver: PlaylistSaver? = {
        let dataManager = MediaDataManager(appDelegate: appDelegate)
        let saver = PlaylistSaver(dataManager: dataManager, fileManager: fileManager)
        return saver
    }()
    
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    func createAlert(title: String? = "Error", error: Error?,
                     msgWithError: String?, action: (() -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title,
                                      message: (error?.localizedDescription ?? "") + " " + (msgWithError ?? ""),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            action?()
        })
        
        return alert
    }
    
    func buildLibraryViewController() -> UIViewController {
        let viewModel = LibraryViewModel(saver: playlistSaver!)
        let controller = LibraryViewController()
        viewModel.delegate = controller
        
        let navController = buildNavigationController(rootController: controller)
        router = LibraryPageRouter(builder: self, navigationController: navController)
        viewModel.router = router
        controller.viewModel = viewModel
        return navController
    }
    
    func buildPlaylistController(playlistID: UUID, playlist: Playlist?) -> UIViewController {
        playlistViewModel = PlaylistViewModel(player: player,
                                              saver: playlistSaver,
                                              id: playlistID,
                                              playlist: playlist)
        playlistViewModel!.router = router
        
        let playlistVC = PlaylistViewController()
        playlistVC.viewModel = playlistViewModel
        return playlistVC
    }
    
    func buildAddItemsToPlaylist(_ fromStorage: [MediaFile], saveAction: (([IndexPath]) -> Void)?) -> UIViewController {
        let controller = SelectMediaFilesTableView(source: fromStorage, saveAction: saveAction)
        return controller
    }
    
    private func buildNavigationController(rootController: UIViewController) -> UINavigationController {
        let navController = UINavigationController(rootViewController: rootController)
        let scrollingAppearance = UINavigationBarAppearance()
        scrollingAppearance.configureWithTransparentBackground()
        scrollingAppearance.backgroundEffect = UIBlurEffect(style: .dark)
        scrollingAppearance.backgroundColor = .clear
        scrollingAppearance.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.titleFont]
        
        navController.navigationBar.scrollEdgeAppearance = scrollingAppearance
        navController.navigationBar.standardAppearance = scrollingAppearance
        
        navController.navigationBar.tintColor = .white
        navController.navigationBar.tintAdjustmentMode = .normal
        return navController
    }
}
