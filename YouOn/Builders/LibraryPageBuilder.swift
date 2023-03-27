//
//  LibraryPageBuilder.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 20.03.2023.
//

import Foundation
import UIKit

protocol LibraryPageBuilderProtocol: BuilderProtocol {
    func buildLibraryViewController() -> UIViewController
    func buildPlaylistController(playlistID: UUID) -> UIViewController
    func buildAddItemsToPlaylist(_ fromStorage: [MediaFile], saveAction: (([IndexPath]) -> Void)?) -> UIViewController
}

class LibraryPageBuilder: LibraryPageBuilderProtocol {
    
    private let fileManager = FileManager.default
    
    private let musicPlayer = MusicPlayer()
    
    private var router: LibraryPageRouter?
    
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
        let saver = PlaylistSaver(dataManager: MediaDataManager(appDelegate: appDelegate), fileManager: fileManager)
        let viewModel = LibraryViewModel(saver: saver)
        let controller = LibraryViewController()
        
        let navController = UINavigationController(rootViewController: controller)
        let scrollingAppearance = UINavigationBarAppearance()
        scrollingAppearance.configureWithTransparentBackground()
        scrollingAppearance.backgroundEffect = UIBlurEffect(style: .dark)
        scrollingAppearance.backgroundColor = .clear
        scrollingAppearance.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.titleFont]
        
        navController.navigationBar.scrollEdgeAppearance = scrollingAppearance
        navController.navigationBar.standardAppearance = scrollingAppearance
        
        navController.navigationBar.tintColor = .white
        navController.navigationBar.tintAdjustmentMode = .normal
        router = LibraryPageRouter(builder: self, navigationController: navController)
        viewModel.router = router
        controller.viewModel = viewModel
        return navController
    }
    
    func buildPlaylistController(playlistID: UUID) -> UIViewController {
        let dataManager = MediaDataManager(appDelegate: appDelegate)
        let saver = PlaylistSaver(dataManager: dataManager, fileManager: fileManager)
        musicPlayer.fileManager = fileManager
        
        let viewModel = PlaylistViewModel(player: musicPlayer,
                                          saver: saver,
                                          id: playlistID)
        viewModel.router = router
        
        let playlistController = PlaylistViewController()
        playlistController.viewModel = viewModel
        return playlistController
    }
    
    func buildAddItemsToPlaylist(_ fromStorage: [MediaFile], saveAction: (([IndexPath]) -> Void)?) -> UIViewController {
        let controller = SelectMediaFilesTableView(source: fromStorage, saveAction: saveAction)
        return controller
    }
}
