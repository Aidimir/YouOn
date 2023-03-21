//
//  MainBuilder.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 21.03.2023.
//

import Foundation
import UIKit

protocol MainBuilderProtocol: BuilderProtocol {
    func buildMainPage() -> UIViewController
    var founderPageBuilder: FounderBuilderProtocol { get }
    var libraryPageBuilder: LibraryPageBuilderProtocol { get }
}

class MainBuilder: MainBuilderProtocol {
    
    var founderPageBuilder: FounderBuilderProtocol = FounderPageBuilder()
    
    var libraryPageBuilder: LibraryPageBuilderProtocol = LibraryPageBuilder()
    
    
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
    
    func buildMainPage() -> UIViewController {
        let founderC = founderPageBuilder.buildFounderPage()
        let libraryC = libraryPageBuilder.buildLibraryViewController()
        let controller = UITabBarController()
        controller.tabBar.tintColor = .white
        controller.tabBar.barTintColor = .black
        controller.viewControllers = [founderC, libraryC]
        return controller
    }
}
