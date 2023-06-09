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
import LNPopupController
import Differentiator
import RxDataSources

protocol MusicPlayerViewProtocol: UIViewController {
    init(musicPlayer: MusicPlayerProtocol, imageCornerRadius: CGFloat, titleScrollingDuration: CGFloat)
}

class MusicPlayerViewController: UIViewController, MusicPlayerViewProtocol, MusicPlayerViewDelegate, MoreActionsTappedDelegate {
    
    func onMoreActionsTapped(cell: UITableViewCell) {
//
    }
    
    
    var dismissAnimationDuration = 0.3
    
    var minimumScreenRatioToDismiss = 0.6
    
    var minimumVelocityToDismiss = CGFloat(1)
    
    var isSeekInProgress: Bool = false
    
    var isScrubbingFlag: Bool = false
    
    private var duration: Float?
    
    private let disposeBag = DisposeBag()
    
    private enum Constants {
        static let verticalPadding = 30
        static let horizontalPadding = 20
        static let smallButtonSize: CGFloat = 50
        static let strokeWidth = 40
        static let mediumButtonSize = 75
    }
    
    private let imagePlaceholder = UIImage(systemName: "music.note")
    
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
    
    private lazy var randomizeOrderButton = UIButton()
    
    private lazy var loopButton = UIButton()
    
    private lazy var showCurrentStorageButton = UIButton()
    
    private var progressBarHighlightedObserver: NSKeyValueObservation?
    
    private var currentStorageTableView: BindableTableViewController<MediaFilesSectionModel>!
    
    private lazy var changePlaybackPositionSlider: UISlider = {
        let bar = UISlider()
        bar.minimumTrackTintColor = .black
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
    
    func updateProgress(progress: Double) {
        let floated = Float(progress)
        if !floated.isNaN && duration != nil {
            popupItem.progress = floated / duration!
            if !isScrubbingFlag && !isSeekInProgress {
                changePlaybackPositionSlider.value = floated
                timeWent.text = progress.stringTime
                timeLeft.text = (Double(duration!) - progress).stringTime
            }
        }
    }
    
    func updateDuration(duration: Double) {
        let floated = Float(duration)
        if !floated.isNaN {
            self.duration = floated
            changePlaybackPositionSlider.maximumValue = floated
        }
    }
    
    required init(musicPlayer: MusicPlayerProtocol,
                  imageCornerRadius: CGFloat = 10,
                  titleScrollingDuration: CGFloat = 2) {
        self.musicPlayer = musicPlayer
        self.imageCornerRadius = imageCornerRadius
        self.titleScrollingDuration = titleScrollingDuration
        super.init(nibName: nil, bundle: nil)
        popupContentView.backgroundColor = .red
        self.musicPlayer.delegate = self
        setBindings()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviews()
    }
    
    private func addSubviews() {
        let dataSource = RxTableViewSectionedAnimatedDataSource<MediaFilesSectionModel> { _, tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "MediaFileCell", for: indexPath) as! MediaFileCell
            cell.setup(file: item,
                       backgroundColor: .darkGray,
                       imageCornerRadius: 10,
                       supportsMoreActions: true)
            cell.delegate = self
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            return cell
        } canEditRowAtIndexPath: { source, indexPath in
            true
        }
        
        let cellsToRegister = ["MediaFileCell": MediaFileCell.self]
        
        currentStorageTableView = BindableTableViewController(items: musicPlayer.storage
            .asObservable()
            .map({ [AnimatableSectionModel(model: "",
                                           items: $0.map({ MediaFileUIModel(model: $0)}))] }),
                                                              heightForRow: view.frame.size.height / 8,
                                                              dataSource: dataSource,
                                                              classesToRegister: cellsToRegister)
        currentStorageTableView?.view.backgroundColor = .lightGray
        currentStorageTableView.tableView.cellLayoutMarginsFollowReadableWidth = true
        
        songImageView.contentMode = .scaleAspectFill
        songImageView.kf.setImage(with: musicPlayer.currentFile?.imageURL, placeholder: imagePlaceholder)
        songImageView.layer.cornerRadius = imageCornerRadius
        songImageView.tintColor = .gray
        songImageView.clipsToBounds = true
        
        timeLeft.textColor = .white
        timeWent.textColor = .white
        
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
        
        let loopImage = UIImage(systemName: "repeat")
        loopButton.setImage(loopImage, for: .normal)
        loopButton.tintColor = .lightGray
        loopButton.addTarget(self, action: #selector(didTapLoop), for: .touchUpInside)
        
        let randomizeOrderImage = UIImage(systemName: "shuffle")
        randomizeOrderButton.setImage(randomizeOrderImage, for: .normal)
        print(musicPlayer.isAlreadyRandomized)
        randomizeOrderButton.tintColor = musicPlayer.isAlreadyRandomized ? .green : .lightGray
        randomizeOrderButton.addTarget(self, action: #selector(didTapRandomize), for: .touchUpInside)
        
        let showCurrentStorageImage = UIImage(systemName: "list.dash")
        showCurrentStorageButton.setImage(showCurrentStorageImage, for: .normal)
        showCurrentStorageButton.tintColor = .white
        showCurrentStorageButton.addTarget(self, action: #selector(didTapShowCurrentStorage), for: .touchUpInside)
        
        let pauseButtonItem = UIBarButtonItem(image: UIImage(systemName: "pause.fill"), style: .plain, target: self, action: #selector(didTapPlay))
        popupItem.trailingBarButtonItems = [pauseButtonItem]
        
        let playImage = UIImage(systemName: "pause.fill")
        playButton.setImage(playImage, for: .normal)
        playButton.tintColor = .white
        playButton.addTarget(self, action: #selector(didTapPlay), for: .touchUpInside)
        playButton.backgroundColor = .black
        playButton.clipsToBounds = true
        playButton.frame = CGRect(x: 0, y: 0, width: Constants.mediumButtonSize, height: Constants.mediumButtonSize)
        
        let stackSubviews = [loopButton, previousButton, playButton, nextButton, randomizeOrderButton]
        let controlButtonsStack = UIStackView(arrangedSubviews: stackSubviews)
        controlButtonsStack.distribution = .equalCentering
        controlButtonsStack.axis = .horizontal
        controlButtonsStack.spacing = CGFloat(Constants.horizontalPadding)
        
        view.addSubview(songImageView)
        songImageView.snp.makeConstraints { make in
            make.left.right.equalTo(view.readableContentGuide)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(Constants.verticalPadding)
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
        
        view.addSubview(showCurrentStorageButton)
        showCurrentStorageButton.snp.makeConstraints { make in
            make.right.equalTo(songImageView)
            make.bottom.equalTo(songImageView.snp.top)
            make.width.height.equalTo(Constants.smallButtonSize)
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
        updateViews()
    }
    
    private func updateViews() {
        songTitle.text = musicPlayer.currentFile?.title
        songAuthor.text = musicPlayer.currentFile?.author
        songImageView.kf.setImage(with: musicPlayer.currentFile?.imageURL, placeholder: imagePlaceholder) { res in
            switch res {
            case .success(let img):
                self.popupItem.image = img.image
            case .failure(_):
                self.popupItem.image = nil
            }
        }
        if musicPlayer.currentFile == nil {
            timeWent.text = nil
        }
        popupItem.title = musicPlayer.currentFile?.title
        popupItem.subtitle = musicPlayer.currentFile?.author
    }
    
    private func setBindings() {
        musicPlayer.isPlaying.asDriver(onErrorJustReturn: false).drive { [weak self] value in
            let playImage = value ? UIImage(systemName: "pause.fill") : UIImage(systemName: "play.fill")
            self?.playButton.setImage(playImage, for: .normal)
            self?.popupItem.trailingBarButtonItems?.first?.image = playImage
        }.disposed(by: disposeBag)
        
        musicPlayer.currentItemDuration.filter({ $0 != nil }).map({ $0! }).asDriver(onErrorJustReturn: 0).drive { [weak self] val in
            let floated = Float(val)
            if !floated.isNaN {
                self?.duration = floated
                self?.timeLeft.text = val.stringTime
                self?.changePlaybackPositionSlider.maximumValue = floated
            }
        }.disposed(by: disposeBag)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playButton.snp.remakeConstraints { make in
            make.width.height.equalTo(Constants.mediumButtonSize)
        }
        playButton.layer.cornerRadius = playButton.frame.height / 2
    }
}

extension MusicPlayerViewController {
    
    @objc private func onSliderDragging(sender: UISlider) {
        musicPlayer.seekTo(seconds: Double(sender.value))
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
    
    @objc private func didTapRandomize() {
        if musicPlayer.currentIndex != nil {
            musicPlayer.randomize(fromIndex: musicPlayer.currentIndex!)
            randomizeOrderButton.tintColor = musicPlayer.isAlreadyRandomized ? .green : .lightGray
            updateViews()
        }
    }

    @objc private func didTapLoop() {
        musicPlayer.isInLoop = !musicPlayer.isInLoop
        loopButton.tintColor = musicPlayer.isInLoop ? .green : .lightGray
        updateViews()
    }

    @objc private func didTapShowCurrentStorage() {
        present(currentStorageTableView!, animated: true)
        updateViews()
    }
}
