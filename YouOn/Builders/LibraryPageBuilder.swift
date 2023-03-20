//
//  LibraryPageBuilder.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 20.03.2023.
//

import Foundation
import UIKit

protocol LibraryPageBuilderProtocol: BuilderProtocol {
    func buildLibraryViewController() -> LibraryViewController
    func buildPlaylistController(playlistID: UUID) -> UIViewController
}

class LibraryPageBuilder: LibraryPageBuilderProtocol {
    
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
    
    func buildLibraryViewController() -> LibraryViewController {
        let saver = PlaylistSaver(dataManager: MediaDataManager(appDelegate: appDelegate))
        let navController = UINavigationController()
        let router = LibraryPageRouter(builder: self, navigationController: navController)
        let viewModel = LibraryViewModel(saver: saver, router: router)
        let controller = LibraryViewController(viewModel: viewModel)
        return controller
    }
    
    func buildPlaylistController(playlistID: UUID) -> UIViewController {
        return UIViewController()
    }
}
