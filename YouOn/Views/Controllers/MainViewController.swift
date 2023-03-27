//
//  MainViewController.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 27.03.2023.
//

import Foundation
import UIKit
import SnapKit

protocol MainViewProtocol {
    var viewModel: MainViewModelProtocol? { get set }
}

class MainViewController: UITabBarController, MainViewProtocol, MainViewModelDelegate {
    
    var viewModel: MainViewModelProtocol? {
        didSet {
            viewModel?.delegate = self
        }
    }
    
    private let playerViewController: MusicPlayerViewController
    
    private var shortedPlayerView: ShortedPlayerView?
    
    init(playerViewController: MusicPlayerViewController) {
        self.playerViewController = playerViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @objc private func presentPlayer() {
        viewModel?.presentPlayer()
    }
    
    func onPlayerFileAppeared(title: String?, author: String?) {
        if shortedPlayerView == nil {
            guard let shortedView = playerViewController.shortedPlayerView else { return }
            shortedPlayerView = shortedView
            shortedPlayerView?.backgroundColor = .gray
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(presentPlayer))
            shortedPlayerView?.addGestureRecognizer(gestureRecognizer)
//            popup with animation
            view.addSubview(shortedPlayerView!)
            shortedPlayerView!.snp.makeConstraints({ make in
                make.bottom.equalTo(tabBar.snp.top)
                make.left.right.equalToSuperview()
                make.height.equalTo(tabBar).multipliedBy(0.8)
            })
        } else {
            shortedPlayerView?.updateValues(currentTitle: title, currentAuthor: author, currentProgress: 0)
        }
    }
}
