//
//  MainBuilder.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 21.03.2023.
//

import Foundation
import UIKit

protocol MainBuilderProtocol: BuilderProtocol {
    func buildMainPage(router: MainRouterProtocol) -> UIViewController
    var founderPageBuilder: FounderBuilderProtocol { get }
    var libraryPageBuilder: LibraryPageBuilderProtocol { get }
    var musicController: MusicPlayerViewController? { get }
}

class MainBuilder: MainBuilderProtocol {
    
    var founderPageBuilder: FounderBuilderProtocol = FounderPageBuilder()
    
    var libraryPageBuilder: LibraryPageBuilderProtocol = LibraryPageBuilder()
    
    var musicController: MusicPlayerViewController?
    
    init() {
        MusicPlayer.shared.fileManager = FileManager.default
    }
    
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
    
    func buildMainPage(router: MainRouterProtocol) -> UIViewController {
        musicController = MusicPlayerViewController(musicPlayer: MusicPlayer.shared)
        
        let mainViewModel = MainViewModel()
        mainViewModel.router = router
        mainViewModel.player = MusicPlayer.shared
        let mainViewController = MainViewController(playerViewController: musicController!)
        mainViewController.viewModel = mainViewModel
        
        let founderC = founderPageBuilder.buildFounderPage()
        let libraryC = libraryPageBuilder.buildLibraryViewController()
        
        mainViewController.tabBar.tintColor = .white
        mainViewController.tabBar.barTintColor = .darkGray
        mainViewController.tabBar.backgroundColor = .darkGray
        mainViewController.tabBar.isTranslucent = false
        mainViewController.setViewControllers([founderC, libraryC], animated: true)
        
        return mainViewController
    }
}
