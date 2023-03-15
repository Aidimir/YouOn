//
//  MainRouter.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 15.03.2023.
//

import Foundation
import UIKit

protocol RouterProtocol {
    var navigationController: UINavigationController { get set }
    func popToRoot()
}

protocol MainRouterProtocol: RouterProtocol {
    var builder: MainBuilderProtocol { get set }
    func initStartViewController()
    func showAlert(title: String, error: Error?, msgWithError: String?, action: (() -> Void)?)
}

class MainRouter: MainRouterProtocol {
    
    var navigationController: UINavigationController
    
    var builder: MainBuilderProtocol
    
    init(builder: MainBuilderProtocol, navigationController: UINavigationController) {
        self.builder = builder
        self.navigationController = navigationController
    }
    
    func initStartViewController() {
        let controller = builder.buildMainPage()
        navigationController.viewControllers = [controller]
    }
    
    func showAlert(title: String, error: Error?, msgWithError: String?, action: (() -> Void)?) {
        let alert = builder.createAlert(title: title, error: error, msgWithError: msgWithError, action: {
            action?()
        })
        
        navigationController.present(alert, animated: true)
    }
    
    func popToRoot() {
        navigationController.popToRootViewController(animated: true)
    }
    
}
