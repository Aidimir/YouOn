//
//  MusicPlayerController.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 27.03.2023.
//

import Foundation
import SnapKit
import UIKit
import Kingfisher
import MarqueeLabel
import RxSwift

protocol MusicPlayerViewProtocol {
    init(musicPlayer: MusicPlayerProtocol, imageCornerRadius: CGFloat, titleScrollingDuration: CGFloat)
}

class MusicPlayerViewController: UIViewController, MusicPlayerViewProtocol, MusicPlayerDelegate {
    
    private let disposeBag = DisposeBag()
    
    var shortedPlayerView: ShortedPlayerView?
    
    private enum Constants {
        static let verticalPadding = 30
        static let horizontalPadding = 20
        static let smallButtonSize = 50
    }
    
    private let imagePlaceholder = UIImage(systemName: "music.note")
    
    private let dismissButton = UIButton()
    
    private var musicPlayer: MusicPlayerProtocol
    
    private var imageCornerRadius: CGFloat
    
    private var titleScrollingDuration: CGFloat
    
    private lazy var songImageView = UIImageView()
    
    private lazy var songTitle = UILabel.createScrollableLabel()
    
    private lazy var songAuthor = UILabel.createScrollableLabel()
    
    private lazy var nextButton = UIButton()
    
    private lazy var previousButton = UIButton()
    
    private lazy var playButton = UIButton()
    
    private lazy var changePlaybackPositionSlider = UISlider()
    
    private var moreActionButtons = [UIButton]()
    
    required init(musicPlayer: MusicPlayerProtocol,
                  imageCornerRadius: CGFloat = 10,
                  titleScrollingDuration: CGFloat = 2) {
        self.musicPlayer = musicPlayer
        self.imageCornerRadius = imageCornerRadius
        self.titleScrollingDuration = titleScrollingDuration
        super.init(nibName: nil, bundle: nil)
        self.musicPlayer.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .lightGray
        
        let dismissArrowImage = UIImage(systemName: "chevron.down")
        dismissButton.setImage(dismissArrowImage, for: .normal)
        dismissButton.addTarget(self, action: #selector(onDismissButtonTapped), for: .touchUpInside)
        dismissButton.tintColor = .white
        
        songImageView.contentMode = .scaleAspectFill
        songImageView.kf.setImage(with: musicPlayer.currentFile?.imageURL, placeholder: imagePlaceholder)
        songImageView.layer.cornerRadius = imageCornerRadius
        songImageView.tintColor = .gray
        songImageView.clipsToBounds = true
        
        songTitle.text = musicPlayer.currentFile?.title
        
        songAuthor.text = musicPlayer.currentFile?.author
        songAuthor.font = .mediumSizeFont
        songAuthor.textColor = .gray
        
        let backImage = UIImage(systemName: "backward.fill")
        previousButton.setImage(backImage, for: .normal)
        previousButton.tintColor = .white
        previousButton.addTarget(self, action: #selector(didTapPrevious), for: .touchUpInside)
        
        let nextImage = UIImage(systemName: "forward.fill")
        nextButton.setImage(nextImage, for: .normal)
        nextButton.tintColor = .white
        nextButton.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)
        
        let playImage = musicPlayer.isPlaying ? UIImage(systemName: "pause.fill") : UIImage(systemName: "play.fill")
        playButton.setImage(playImage, for: .normal)
        playButton.tintColor = .white
        playButton.addTarget(self, action: #selector(didTapPlay), for: .touchUpInside)
        
        let controlButtonsStack = UIStackView(arrangedSubviews: [previousButton, playButton, nextButton])
        controlButtonsStack.distribution = .fillEqually
        controlButtonsStack.axis = .horizontal
        
        view.addSubview(dismissButton)
        dismissButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.equalTo(view.readableContentGuide)
            make.height.width.equalTo(Constants.smallButtonSize)
        }
        
        view.addSubview(songImageView)
        songImageView.snp.makeConstraints { make in
            make.left.right.equalTo(view.readableContentGuide)
            make.top.equalTo(dismissButton.snp.bottom).offset(Constants.verticalPadding)
            make.height.equalTo(view).dividedBy(3)
        }
        
        view.addSubview(songTitle)
        songTitle.snp.makeConstraints { make in
            make.top.equalTo(songImageView.snp.bottom).offset(Constants.verticalPadding)
            make.left.right.equalTo(view.readableContentGuide)
        }
        
        view.addSubview(songAuthor)
        songAuthor.snp.makeConstraints { make in
            make.top.equalTo(songTitle.snp.bottom).offset(Constants.verticalPadding)
            make.left.right.equalTo(view.readableContentGuide)
        }
        
        view.addSubview(controlButtonsStack)
        controlButtonsStack.snp.makeConstraints { make in
            make.top.equalTo(songAuthor.snp.bottom).offset(Constants.verticalPadding)
            make.left.right.equalTo(view.readableContentGuide)
            make.height.equalTo(view).dividedBy(10)
        }
    }
    
    @objc private func onDismissButtonTapped() {
        dismiss(animated: true)
    }
    
    func onPlayNext() {
        updateViews()
    }
    
    func onPlayPrevious() {
        updateViews()
    }
    
    func errorHandler(error: Error) {
        let alert = UIAlertController(title: "Error",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
    
    func onPause() {
        updateViews()
    }
    
    func onPlay() {
        if shortedPlayerView == nil {
            shortedPlayerView = ShortedPlayerView(currentTitle: musicPlayer.currentFile?.title,
                                                  currentAuthor: musicPlayer.currentFile?.author,
                                                  currentProgress: 0,
                                                  buttonIcon: UIImage(systemName: "pause.fill"),
                                                  onActionButtonTapped: musicPlayer.playTapped)
        }
        
        updateViews()
    }
    
    @objc private func didTapPrevious() {
        musicPlayer.playPrevious()
    }
    
    @objc private func didTapNext() {
        musicPlayer.playNext()
    }
    
    @objc private func didTapPlay() {
        musicPlayer.playTapped()
        updateViews()
    }
    
    private func updateViews() {
        songTitle.text = musicPlayer.currentFile?.title
        songAuthor.text = musicPlayer.currentFile?.author
        let playImage = musicPlayer.isPlaying ? UIImage(systemName: "pause.fill") : UIImage(systemName: "play.fill")
        playButton.setImage(playImage, for: .normal)
        shortedPlayerView?.actionButton.setImage(playImage, for: .normal)
        songImageView.kf.setImage(with: musicPlayer.currentFile?.imageURL, placeholder: imagePlaceholder)
    }
    
    override func viewDidLayoutSubviews() {
        updateViews()
    }
}
