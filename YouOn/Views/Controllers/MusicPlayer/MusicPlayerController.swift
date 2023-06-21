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
import RxCocoa
import PopMenu
import ESTMusicIndicator

protocol MusicPlayerViewProtocol: UIViewController {
    init(musicPlayer: MusicPlayerProtocol, imageCornerRadius: CGFloat, titleScrollingDuration: CGFloat)
}

class MusicPlayerViewController: UIViewController, MusicPlayerViewProtocol, MusicPlayerViewDelegate, MoreActionsTappedDelegate {
    
    private var popMenuViewController: PopMenuViewController?
    
    var currentStorageViewController: CurrentStorageViewController?
    
    func onMoreActionsTapped(cell: UITableViewCell) {
        let actions = musicPlayer.fetchActionModels(indexPath: (currentStorageTableView?.tableView.indexPath(for: cell)!)!).map { element in
            
            var image: UIImage? = nil
            if element.iconName != nil {
                image = UIImage(systemName: element.iconName!)
            }
            
            let action = PopMenuDefaultAction(title: element.title, image: image, color: UIColor.white) { action in element.onTap?() }
            return action
        }
        
        if let cell = cell as? MediaFileCell {
            popMenuViewController = PopMenuViewController(sourceView: cell.moreActionsButton, actions: actions)
            
            popMenuViewController!.appearance.popMenuFont = .mediumSizeBoldFont
            popMenuViewController!.appearance.popMenuBackgroundStyle = .dimmed(color: .black, opacity: 0.6)
            popMenuViewController!.appearance.popMenuItemSeparator = .fill()
            currentStorageViewController!.present(popMenuViewController!, animated: true)
        }
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
        static let smallVerticalPadding = 10
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
    
    private var cellToTrack: MediaFileCell?
    
    private var onItemSelected: (IndexPath) -> () {
        return { [weak self] (indexPath) in
            self?.musicPlayer.play(index: indexPath.row, updatesStorage: false)
        }
    }
    
    private var onItemMoved: (ItemMovedEvent) -> () {
        return { [weak self] (event) in
            guard let item = self?.musicPlayer.storage.value[event.sourceIndex.row] else { return }
            self?.musicPlayer.storage.replaceElement(at: event.sourceIndex.row, insertTo: event.destinationIndex.row, with: item)
            self?.musicPlayer.updateOnUiChanges()
        }
    }
    
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
        self.musicPlayer.delegate = self
        popupContentView.backgroundColor = .red
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviews()
        setBindings()
    }
    
    private func addSubviews() {
        let dataSource = RxTableViewSectionedAnimatedDataSource<MediaFilesSectionModel> { [weak self] _, tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "MediaFileCell", for: indexPath) as! MediaFileCell
            cell.setup(file: item,
                       backgroundColor: .darkGray,
                       imageCornerRadius: 10,
                       supportsMoreActions: true)
            cell.delegate = self
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            
            if let disposeBag = self?.disposeBag {
                if let id = self?.musicPlayer.currentFile.value?.playlistSpecID {
                    if id == item.playlistSpecID {
                        self?.musicPlayer.isPlaying.take(while: { val in
                            cell.playState = val ? .playing : .paused
                            return self?.musicPlayer.currentFile.value?.playlistSpecID?.uuidString == item.identity
                        }).bind(to: cell.rx.isPlaying).disposed(by: disposeBag)
                    } else {
                        cell.playState = .stopped
                    }
                } else {
                    if self?.musicPlayer.currentFile.value?.id == item.identity {
                        if self?.cellToTrack == nil || self?.cellToTrack == cell {
                            self?.musicPlayer.isPlaying.take(while: { val in
                                cell.playState = val ? .playing : .paused
                                return self?.musicPlayer.currentFile.value?.id == item.identity
                            }).bind(to: cell.rx.isPlaying).disposed(by: disposeBag)
                            self?.cellToTrack = cell
                        }
                    } else {
                        cell.playState = .stopped
                    }
                }
            }
            
            return cell
        } canEditRowAtIndexPath: { source, indexPath in
            return true
        } canMoveRowAtIndexPath: { source, indexPath in
            return true
        }
        
        let classesToRegister = ["MediaFileCell": MediaFileCell.self]
        
        currentStorageTableView = BindableTableViewController(items: musicPlayer.storage
            .asObservable()
            .map({ [MediaFilesSectionModel(model: "",
                                           items: $0.map({ MediaFileUIModel(model: $0)}))] }),
                                                              heightForRow: view.frame.size.height / 8,
                                                              onItemSelected: onItemSelected,
                                                              onItemMoved: onItemMoved,
                                                              dataSource: dataSource,
                                                              classesToRegister: classesToRegister,
                                                              supportsDragging: true)
        currentStorageTableView?.view.backgroundColor = .darkGray
        currentStorageTableView.tableView.cellLayoutMarginsFollowReadableWidth = true
        
        songImageView.contentMode = .scaleAspectFill
        songImageView.kf.setImage(with: musicPlayer.currentFile.value?.imageURL, placeholder: imagePlaceholder)
        songImageView.layer.cornerRadius = imageCornerRadius
        songImageView.tintColor = .gray
        songImageView.clipsToBounds = true
        
        timeLeft.textColor = .white
        timeWent.textColor = .white
        
        songTitle.text = musicPlayer.currentFile.value?.title
        
        songAuthor.text = musicPlayer.currentFile.value?.author
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
            make.width.equalTo(view.readableContentGuide).multipliedBy(0.75)
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
    
    private func setBindings() {
        musicPlayer.isPlaying.asDriver(onErrorJustReturn: false).drive { [weak self] value in
            let playImage = value ? UIImage(systemName: "pause.fill") : UIImage(systemName: "play.fill")
            self?.playButton.setImage(playImage, for: .normal)
            self?.popupItem.trailingBarButtonItems?.first?.image = playImage
            
            if self?.currentStorageTableView != nil,
               let model = self?.musicPlayer.currentFile.value,
               let cells = (self?.currentStorageTableView?.tableView.visibleCells as? [MediaFileCell])?.filter({ $0.file?.id == model.id }), cells.count > 0 {
                cells.forEach({ $0.playState = .stopped })
                if self?.musicPlayer.currentFile.value?.playlistSpecID != nil {
                    cells.first(where: { $0.file?.playlistSpecID == self?.musicPlayer.currentFile.value?.playlistSpecID })?.playState = value ? .playing : .paused
                } else {
                    cells.first?.playState = value ? .playing : .paused
                }            }
        }.disposed(by: disposeBag)
        
        musicPlayer.currentItemDuration.filter({ $0 != nil }).map({ $0! }).asDriver(onErrorJustReturn: 0).drive { [weak self] val in
            let floated = Float(val)
            if !floated.isNaN {
                self?.duration = floated
                self?.timeLeft.text = val.stringTime
                self?.changePlaybackPositionSlider.maximumValue = floated
            }
        }.disposed(by: disposeBag)
        
        musicPlayer.currentFile.asDriver().filter({ $0 != nil }).drive { [weak self] file in
            self?.cellToTrack = nil
            self?.songTitle.text = file!.title
            self?.songAuthor.text = file!.author
            self?.songImageView.kf.setImage(with: file!.imageURL, placeholder: self?.imagePlaceholder) { res in
                switch res {
                case .success(let img):
                    self?.popupItem.image = img.image
                case .failure(_):
                    self?.popupItem.image = nil
                }
            }
            self?.popupItem.title = file!.title
            self?.popupItem.subtitle = file!.author
            
            if self?.currentStorageTableView != nil, let allCells = (self?.currentStorageTableView?.tableView.visibleCells as? [MediaFileCell])?.filter({ $0.file?.id != file?.id }) {
                allCells.forEach({ $0.playState = .stopped })
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
    }
    
    @objc private func didTapRandomize() {
        if musicPlayer.currentIndex.value != nil {
            musicPlayer.randomize(fromIndex: musicPlayer.currentIndex.value!)
            randomizeOrderButton.tintColor = musicPlayer.isAlreadyRandomized ? .green : .lightGray
        }
    }
    
    @objc private func didTapLoop() {
        musicPlayer.isInLoop = !musicPlayer.isInLoop
        loopButton.tintColor = musicPlayer.isInLoop ? .green : .lightGray
    }
    
    @objc private func didTapShowCurrentStorage() {
        currentStorageViewController = CurrentStorageViewController(tableView: currentStorageTableView.tableView)
        currentStorageViewController?.modalPresentationStyle = .custom
        currentStorageViewController?.transitioningDelegate = self
        present(currentStorageViewController!, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.currentStorageTableView.tableView.scrollToRow(at: IndexPath(row: self?.musicPlayer.currentIndex.value ?? 0, section: 0), at: .middle, animated: true)
        }
    }
}

extension MusicPlayerViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        PresentationController(presentedViewController: presented, presenting: presenting)
    }
}
