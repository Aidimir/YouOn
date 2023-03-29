////
////  MainViewController.swift
////  YouOn
////
////  Created by Айдимир Магомедов on 27.03.2023.
////
//
//import Foundation
//import UIKit
//import SnapKit
//import LNPopupController
//import RxSwift
//import RxCocoa
//
//protocol MainViewProtocol {
//    var viewModel: MainViewModelProtocol? { get set }
//}
//
//class MainViewController: UITabBarController, MainViewProtocol, MainViewModelDelegate {
//
//    var viewModel: MainViewModelProtocol? {
//        didSet {
//            viewModel?.delegate = self
//        }
//    }
//
//    private let disposeBag = DisposeBag()
//
//    private var shortedPlayerView: ShortedPlayerView?
//
//    private lazy var blur = UIBlurEffect(style: .dark)
//
//    private lazy var blurView = UIVisualEffectView(effect: blur)
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        tabBar.blurBackground(style: .dark)
//    }
//
//    func onPlayerFileAppeared(title: String?, author: String?) {
//        if shortedPlayerView == nil {
//            guard let shortedView = playerViewController.shortedPlayerView else { return }
//            shortedPlayerView = shortedView
//            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(presentPlayer))
//            shortedPlayerView?.addGestureRecognizer(gestureRecognizer)
//            //            popup with animation
//            view.addSubview(shortedPlayerView!)
//            shortedPlayerView!.snp.makeConstraints({ make in
//                make.bottom.equalTo(tabBar.snp.top)
//                make.left.right.equalToSuperview()
//                make.height.equalTo(tabBar).multipliedBy(0.8)
//            })
//
//            blurView.snp.remakeConstraints { make in
//                make.top.equalTo(shortedPlayerView!)
//                make.left.right.bottom.equalTo(tabBar)
//            }
//        }
//    }
//}
