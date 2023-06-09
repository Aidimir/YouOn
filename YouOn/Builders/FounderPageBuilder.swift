//
//  FounderPageBuilder.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 15.03.2023.
//

import Foundation
import UIKit

protocol BuilderProtocol {
    func createAlert(title: String?, error: Error?, msgWithError: String?, action: (() -> Void)?) -> UIAlertController
}

protocol FounderBuilderProtocol: BuilderProtocol {
    func buildFounderPage() -> UIViewController
}

class FounderPageBuilder: FounderBuilderProtocol {
    
    private let fileManager = FileManager.default
    
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
    
    func buildFounderPage() -> UIViewController {
        let dataManager = MediaDataManager(appDelegate: appDelegate)
        let saver = MediaSaver(dataManager: dataManager, fileManager: fileManager)
        let networkService = YTNetworkService(saver: saver, fileManager: fileManager)
        let viewModel = VideoFounderViewModel(networkService: networkService)
        let controller = VideoFounderViewController(viewModel: viewModel)
        let navController = UINavigationController(rootViewController: controller)
        let router = FounderRouter(builder: self, navigationController: navController)
        viewModel.router = router
        navController.navigationBar.topItem?.title = nil
        navController.navigationBar.tintColor = .white
        return navController
    }
}
