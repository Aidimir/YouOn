//
//  FounderPageRouter.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 21.03.2023.
//

import Foundation
import UIKit

protocol FounderRouterProtocol: RouterProtocol {
    var builder: FounderBuilderProtocol { get set }
    func initStartViewController()
}

class FounderRouter: FounderRouterProtocol {
    
    var navigationController: UINavigationController
    
    var builder: FounderBuilderProtocol
    
    init(builder: FounderBuilderProtocol, navigationController: UINavigationController) {
        self.builder = builder
        self.navigationController = navigationController
    }
    
    func initStartViewController() {
        let controller = builder.buildFounderPage()
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
