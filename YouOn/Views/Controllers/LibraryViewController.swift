//
//  LibraryViewController.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 20.03.2023.
//

import Foundation
import UIKit

protocol LibraryViewProtocol {
    var viewModel: any LibraryViewModelProtocol { get set }
}

class LibraryViewController: UIViewController, LibraryViewProtocol {
    var viewModel: any LibraryViewModelProtocol
    
    init(viewModel: any LibraryViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
