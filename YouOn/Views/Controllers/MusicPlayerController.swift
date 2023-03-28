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

protocol MusicPlayerViewProtocol: UIViewController {
    var shortedPlayerView: ShortedPlayerView? { get }
    init(musicPlayer: MusicPlayerProtocol, imageCornerRadius: CGFloat, titleScrollingDuration: CGFloat)
}

class MusicPlayerViewController: UIViewController, MusicPlayerViewProtocol, MusicPlayerViewDelegate {
    
    private var isShowingFirstTime: Bool = true
    
    var dismissAnimationDuration = 0.3
    
    var minimumScreenRatioToDismiss = 0.6
    
    var minimumVelocityToDismiss = CGFloat(1)
        
    var isSeekInProgress: Bool = false
    
    var isScrubbingFlag: Bool = false
    
    private var duration: Float?
    
    func updateProgress(progress: Double) {
        let floated = Float(progress)
        if !floated.isNaN && duration != nil {
            shortedPlayerView?.updateProgress(progress: floated / duration!)
            if !isScrubbingFlag && !isSeekInProgress {
                changePlaybackPositionSlider.value = floated
                timeWent.text = progress.stringTime
                timeLeft.text = (Double(duration!) - progress).stringTime
            }
        }
    }
    
    private let disposeBag = DisposeBag()
    
    var shortedPlayerView: ShortedPlayerView?
    
    private enum Constants {
        static let verticalPadding = 30
        static let horizontalPadding = 20
        static let smallButtonSize = 50
        static let strokeWidth = 40
        static let mediumButtonSize = 75
    }
    
    private let imagePlaceholder = UIImage(systemName: "music.note")
    
    private let dismissButton = UIButton()
    
    private var musicPlayer: MusicPlayerProtocol
    
    private var imageCornerRadius: CGFloat
    
    private var titleScrollingDuration: CGFloat
    
    private lazy var songImageView = UIImageView()
    
    private lazy var songTitle = UILabel.createScrollableLabel()
    
    private lazy var songAuthor = UILabel.createScrollableLabel()
    
    private lazy var timeWent = UILabel()
    
    private lazy var timeLeft = UILabel()
    
    private lazy var nextButton = UIButton()
    
    private lazy var previousButton = UIButton()
    
    private lazy var playButton = UIButton()
    
    private var progressBarHighlightedObserver: NSKeyValueObservation?
    
    private lazy var changePlaybackPositionSlider: UISlider = {
        let bar = UISlider()
        bar.minimumTrackTintColor = .darkGray
        bar.maximumTrackTintColor = .white
        bar.value = 0.0
        bar.isContinuous = false
        bar.addTarget(self, action: #selector(onSliderDragging), for: .valueChanged)
        self.progressBarHighlightedObserver = bar.observe(\UISlider.isTracking, options: [.old, .new]) { (_, change) in
            if let newValue = change.newValue {
                self.isScrubbingFlag = newValue
                self.timeWent.text = Double(bar.value).stringTime
                self.timeLeft.text = Double(self.duration! - bar.value).stringTime
            }
        }
        return bar
    }()
    
    private var moreActionButtons = [UIButton]()
    
    required init(musicPlayer: MusicPlayerProtocol,
                  imageCornerRadius: CGFloat = 10,
                  titleScrollingDuration: CGFloat = 2) {
        self.musicPlayer = musicPlayer
        self.imageCornerRadius = imageCornerRadius
        self.titleScrollingDuration = titleScrollingDuration
        super.init(nibName: nil, bundle: nil)
        self.musicPlayer.delegate = self
        setBindings()
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
        
        let playImage = UIImage(systemName: "pause.fill")
        playButton.setImage(playImage, for: .normal)
        playButton.tintColor = .white
        playButton.addTarget(self, action: #selector(didTapPlay), for: .touchUpInside)
        playButton.backgroundColor = .black
        playButton.clipsToBounds = true
        playButton.frame = CGRect(x: 0, y: 0, width: Constants.mediumButtonSize, height: Constants.mediumButtonSize)
        
        let stackSubviews = [previousButton, playButton, nextButton]
        let controlButtonsStack = UIStackView(arrangedSubviews: stackSubviews)
        controlButtonsStack.distribution = .equalCentering
        controlButtonsStack.axis = .horizontal
        controlButtonsStack.spacing = CGFloat(Constants.horizontalPadding)
        
        view.addSubview(dismissButton)
        dismissButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(view.safeAreaInsets.top)
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
            make.top.equalTo(songTitle.snp.bottom)
            make.left.right.equalTo(view.readableContentGuide)
        }
        
        view.addSubview(changePlaybackPositionSlider)
        changePlaybackPositionSlider.snp.makeConstraints { make in
            make.left.right.equalTo(view.readableContentGuide)
            make.top.equalTo(songAuthor.snp.bottom).offset(Constants.verticalPadding)
            make.height.equalTo(Constants.strokeWidth)
        }
        
        view.addSubview(timeWent)
        timeWent.snp.makeConstraints { make in
            make.left.equalTo(changePlaybackPositionSlider)
            make.top.equalTo(changePlaybackPositionSlider.snp.bottom)
        }
        
        view.addSubview(timeLeft)
        timeLeft.snp.makeConstraints { make in
            make.right.equalTo(changePlaybackPositionSlider)
            make.top.equalTo(changePlaybackPositionSlider.snp.bottom)
        }
        
        view.addSubview(controlButtonsStack)
        controlButtonsStack.snp.makeConstraints { make in
            make.centerX.equalTo(changePlaybackPositionSlider)
            make.centerY.equalTo(view.frame.maxY - (changePlaybackPositionSlider.frame.maxY * 5))
            make.width.equalTo(view.readableContentGuide).multipliedBy(0.65)
            make.height.equalTo(Constants.mediumButtonSize)
        }
        
        let gestureRecognizer = UIPanGestureRecognizer(target: self,
                                                       action: #selector(panGestureRecognizerHandler(_:)))
        view.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc private func onDismissButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func panGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        func slideViewVerticallyTo(_ y: CGFloat) {
            self.view.frame.origin = CGPoint(x: 0, y: y)
        }

        switch sender.state {

        case .began, .changed:
            // If pan started or is ongoing then
            // slide the view to follow the finger
            let translation = sender.translation(in: view)
            let y = max(0, translation.y)
            slideViewVerticallyTo(y)

        case .ended:
            // If pan ended, decide it we should close or reset the view
            // based on the final position and the speed of the gesture
            let translation = sender.translation(in: view)
            let velocity = sender.velocity(in: view)
            let closing = (translation.y > self.view.frame.size.height * minimumScreenRatioToDismiss) ||
                          (velocity.y > minimumVelocityToDismiss)

            if closing {
                UIView.animate(withDuration: dismissAnimationDuration, animations: {
                    // If closing, animate to the bottom of the view
                    slideViewVerticallyTo(self.view.frame.size.height)
                }, completion: { [weak self] (isCompleted) in
                    if isCompleted {
                        // Dismiss the view when it dissapeared
                        self?.dismiss(animated: false, completion: nil)
                    }
                })
            } else {
                // If not closing, reset the view to the top
                UIView.animate(withDuration: dismissAnimationDuration, animations: {
                    slideViewVerticallyTo(0)
                })
            }

        default:
            // If gesture state is undefined, reset the view to the top
            UIView.animate(withDuration: dismissAnimationDuration, animations: {
                slideViewVerticallyTo(0)
            })

        }
    }
    
    func errorHandler(error: Error) {
        let alert = UIAlertController(title: "Error",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
    
    func onItemChanged() {
        if shortedPlayerView == nil {
            shortedPlayerView = ShortedPlayerView(currentTitle: musicPlayer.currentFile?.title,
                                                  currentAuthor: musicPlayer.currentFile?.author,
                                                  currentProgress: 0,
                                                  buttonIcon: UIImage(systemName: "pause.fill"),
                                                  onActionButtonTapped: musicPlayer.playTapped)
        } else {
            shortedPlayerView?.updateValues(currentTitle: musicPlayer.currentFile?.title, currentAuthor: musicPlayer.currentFile?.author)
            shortedPlayerView?.updateProgress(progress: 0)
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
        songImageView.kf.setImage(with: musicPlayer.currentFile?.imageURL, placeholder: imagePlaceholder)
        timeWent.text = nil
    }
    
    private func setBindings() {
        musicPlayer.isPlaying.asDriver(onErrorJustReturn: false).drive { value in
            let playImage = value ? UIImage(systemName: "pause.fill") : UIImage(systemName: "play.fill")
            self.playButton.setImage(playImage, for: .normal)
            self.shortedPlayerView?.actionButton.setImage(playImage, for: .normal)
        }.disposed(by: disposeBag)
        
        musicPlayer.currentItemDuration.filter({ $0 != nil }).map({ $0! }).asDriver(onErrorJustReturn: 0).drive { val in
            let floated = Float(val)
            if !floated.isNaN {
                self.duration = floated
                self.timeLeft.text = val.stringTime
                self.changePlaybackPositionSlider.maximumValue = floated
            }
        }.disposed(by: disposeBag)
    }
    
    @objc private func onSliderDragging(sender: UISlider) {
        musicPlayer.seekTo(seconds: Double(sender.value))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playButton.snp.remakeConstraints { make in
            make.width.height.equalTo(Constants.mediumButtonSize)
        }
        playButton.layer.cornerRadius = playButton.frame.height / 2
        
        if isShowingFirstTime {
            dismissButton.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(view.safeAreaInsets.top)
                make.left.equalTo(view.readableContentGuide)
                make.height.width.equalTo(Constants.smallButtonSize)
            }
            isShowingFirstTime = false
        }
    }
}
