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
        title = "Library"
        tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: "books.vertical")?.withTintColor(.black), selectedImage: UIImage(systemName: "books.vertical.fill")?.withTintColor(.black))

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
