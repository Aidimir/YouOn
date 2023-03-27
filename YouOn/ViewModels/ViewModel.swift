//
//  ViewModel.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 22.03.2023.
//

import Foundation

protocol ViewModelProtocol {
    func errorHandler(_ error: Error)
}

protocol MainViewModelDelegate {
    func onPlayerFileAppeared(title: String?, author: String?)
}

protocol MainViewModelProtocol: ViewModelProtocol {
    var player: MusicPlayerProtocol? { get }
    var router: MainRouterProtocol? { get }
    var delegate: MainViewModelDelegate? { get set }
    func presentPlayer()
}

class MainViewModel: MainViewModelProtocol {

    var player: MusicPlayerProtocol?
    
    var router: MainRouterProtocol?
    
    var delegate: MainViewModelDelegate?
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateValue), name: NotificationCenterNames.playedSong, object: nil)
    }
    
    func presentPlayer() {
        router?.openPlayerViewController()
    }
    
    @objc private func updateValue() {
        print(player?.storage)
        print(player?.currentFile)
        delegate?.onPlayerFileAppeared(title: player?.currentFile?.title, author: player?.currentFile?.author)
    }
    
    func errorHandler(_ error: Error) {
        router?.showAlert(title: "Error", error: error, msgWithError: nil, action: nil)
    }
}
