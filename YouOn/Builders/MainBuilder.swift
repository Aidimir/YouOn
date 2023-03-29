//
//  MainBuilder.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 21.03.2023.
//

import Foundation
import UIKit

protocol MainBuilderProtocol: BuilderProtocol {
    func buildMainPage(router: MainRouterProtocol) -> UITabBarController
    var founderPageBuilder: FounderBuilderProtocol { get }
    var libraryPageBuilder: LibraryPageBuilderProtocol { get }
}

class MainBuilder: MainBuilderProtocol {
    
    var founderPageBuilder: FounderBuilderProtocol = FounderPageBuilder()
    
    var libraryPageBuilder: LibraryPageBuilderProtocol = LibraryPageBuilder()
    
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    private let fileManager = FileManager.default
    
    private var musicController: MusicPlayerViewController?
    
    private lazy var player: MusicPlayer = {
        let player = MusicPlayer.shared
        let dataManager = PlayerDataManager(appDelegate: appDelegate)
        player.dataManager = dataManager
        player.fileManager = fileManager
        return player
    }()
        
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
    
    func buildMainPage(router: MainRouterProtocol) -> UITabBarController {
        musicController = MusicPlayerViewController(musicPlayer: player)
        let mainViewModel = MainViewModel()
        mainViewModel.router = router
        mainViewModel.player = MusicPlayer.shared
        let mainViewController = MainViewController(playerViewController: musicController!)
        mainViewController.viewModel = mainViewModel
        let founderC = founderPageBuilder.buildFounderPage()
        let libraryC = libraryPageBuilder.buildLibraryViewController()
        
        mainViewController.tabBar.tintColor = .white
        mainViewController.tabBar.barTintColor = .clear
        mainViewController.tabBar.backgroundColor = .clear
        mainViewController.setViewControllers([founderC, libraryC], animated: true)
        
        return mainViewController
    }
}
