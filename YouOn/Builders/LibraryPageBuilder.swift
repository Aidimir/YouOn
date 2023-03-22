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
}

class LibraryPageBuilder: LibraryPageBuilderProtocol {
    
    private let musicPlayer = MusicPlayer()

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
        let saver = PlaylistSaver(dataManager: MediaDataManager(appDelegate: appDelegate))
        let viewModel = LibraryViewModel(saver: saver)
        let controller = LibraryViewController()
        let navController = UINavigationController(rootViewController: controller)
        navController.navigationBar.topItem?.title = nil
        let router = LibraryPageRouter(builder: self, navigationController: navController)
        viewModel.router = router
        controller.viewModel = viewModel
        return navController
    }
    
    func buildPlaylistController(playlistID: UUID) -> UIViewController {
        let dataManager = MediaDataManager(appDelegate: appDelegate)
        let saver = PlaylistSaver(dataManager: dataManager)
        let viewModel = PlaylistViewModel(player: musicPlayer,
                                          saver: saver,
                                          router: nil,
                                          id: playlistID)
        let playlistController = PlaylistViewController()
        playlistController.viewModel = viewModel
        return playlistController
    }
}
