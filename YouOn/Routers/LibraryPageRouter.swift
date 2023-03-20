//
//  LibraryPageRouter.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 20.03.2023.
//

import Foundation
import UIKit

protocol LibraryPageRouterProtocol: RouterProtocol {
    var builder: LibraryPageBuilderProtocol { get set }
    func initPlaylistsViewController()
    func moveToPlaylist(playlistID: UUID)
}

class LibraryPageRouter: LibraryPageRouterProtocol {
    
    var builder: LibraryPageBuilderProtocol
    
    var navigationController: UINavigationController
    
    init(builder: LibraryPageBuilderProtocol, navigationController: UINavigationController) {
        self.builder = builder
        self.navigationController = navigationController
    }

    func initPlaylistsViewController() {
        let controller = builder.buildLibraryViewController()
        navigationController.viewControllers = [controller]
    }
    
    func moveToPlaylist(playlistID: UUID) {
        let controller = builder.buildPlaylistController(playlistID: playlistID)
        navigationController.pushViewController(controller, animated: true)
    }
    
    func showAlert(title: String, error: Error?, msgWithError: String?, action: (() -> Void)?) {
        var alert = builder.createAlert(title: title, error: error, msgWithError: msgWithError, action: action)
        navigationController.pushViewController(alert, animated: true)
    }
    
    func popToRoot() {
        navigationController.popToRootViewController(animated: true)
    }
    
    
}
