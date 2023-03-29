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
    
    private let playerViewController: MusicPlayerViewProtocol
    
    private var shortedPlayerView: ShortedPlayerView?
    
    private lazy var blur = UIBlurEffect(style: .dark)
    
    private lazy var blurView = UIVisualEffectView(effect: blur)

    
    init(playerViewController: MusicPlayerViewProtocol) {
        self.playerViewController = playerViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.left.right.bottom.top.equalTo(tabBar)
        }

        view.bringSubviewToFront(tabBar)
    }
    
    @objc private func presentPlayer() {
        viewModel?.presentPlayer()
    }
    
    func onPlayerFileAppeared(title: String?, author: String?) {
        if shortedPlayerView == nil {
            guard let shortedView = playerViewController.shortedPlayerView else { return }
            shortedPlayerView = shortedView
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(presentPlayer))
            shortedPlayerView?.addGestureRecognizer(gestureRecognizer)
            //            popup with animation
            view.addSubview(shortedPlayerView!)
            shortedPlayerView!.snp.makeConstraints({ make in
                make.bottom.equalTo(tabBar.snp.top)
                make.left.right.equalToSuperview()
                make.height.equalTo(tabBar).multipliedBy(0.8)
            })
            
            blurView.snp.remakeConstraints { make in
                make.top.equalTo(shortedPlayerView!)
                make.left.right.bottom.equalTo(tabBar)
            }
        }
    }
}
