//
//  MusicPlayer.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 17.03.2023.
//

import Foundation
import AVFAudio
import AVFoundation
import UIKit
import MediaPlayer
import RxRelay
import RxSwift
import RxCocoa

protocol MusicPlayerViewDelegate: AnyObject {
    var isScrubbingFlag: Bool { get set }
    var isSeekInProgress: Bool { get set }
    func onItemChanged()
    func updateDuration(duration: Double)
    func updateProgress(progress: Double)
    func errorHandler(error: Error)
}

protocol MusicPlayerControlProtocol: AnyObject {
    func seekTo(seconds: Double)
    func playNext()
    func playPrevious()
    func play(index: Int, updatesStorage: Bool?)
    func playTapped()
    func pause()
    func continuePlay()
    func randomize(fromIndex: Int)
    var isInLoop: Bool { get set }
    var isAlreadyRandomized: Bool { get }
}

protocol MusicPlayerProtocol: AnyObject, MusicPlayerControlProtocol {
    var dataManager: PlayerDataManagerProtocol? { get set }
    var currentFile: MediaFileUIProtocol? { get }
    var currentIndex: Int? { get }
    var isPlaying: Observable<Bool> { get }
    var currentItemDuration: Observable<Double?> { get }
    var delegate: MusicPlayerViewDelegate? { get set }
    var storage: BehaviorRelay<[MediaFileUIProtocol]> { get }
    var fileManager: FileManager? { get set }
}

class MusicPlayer: NSObject, MusicPlayerProtocol, MusicPlayerControlProtocol {
    
    var isInLoop: Bool = false
    
    var storage: RxRelay.BehaviorRelay<[MediaFileUIProtocol]> = BehaviorRelay(value: [])
    
    private var unmodifiedStorage: [MediaFileUIProtocol]? = nil
    
    private var savedInfo: PlayerInfo?
    
    var dataManager: PlayerDataManagerProtocol? {
        didSet {
            let info = try? dataManager?.fetchSavedData()
            savedInfo = info
            if info != nil {
                currentIndex = savedInfo!.currentIndex
                storage.accept(savedInfo!.storage)
                if  let unmodifiedStorage = savedInfo?.unmodifiedStorage {
                    self.unmodifiedStorage = unmodifiedStorage
                    isAlreadyRandomized = savedInfo?.isRandomized ?? false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.play(index: info!.currentIndex)
                    self?.pause()
                    self?.seekTo(seconds: info!.currentTime)
                    self?.delegate?.updateDuration(duration: info!.duration)
                    self?.delegate?.updateProgress(progress: info!.currentTime)
                }
            }
        }
    }
    
    var isPlaying: Observable<Bool> {
        get {
            return player.rx.isPlaying
        }
    }
    
    var currentItemDuration: Observable<Double?> {
        get {
            return player.rx.currentDuration
        }
    }
    
    var currentFile: MediaFileUIProtocol? {
        get {
            if currentIndex != nil {
                return storage.value[currentIndex!]
            }
            return nil
        }
    }
    
    var fileManager: FileManager?
    
    weak var delegate: MusicPlayerViewDelegate?
    
    var currentIndex: Int?
    
    private var alreadyPlayed: [MediaFileUIProtocol] = []
    
    var isAlreadyRandomized: Bool = false
    
    private var player: AVPlayer = AVPlayer()
    
    private let disposeBag = DisposeBag()
    
    static let shared = MusicPlayer()
    
    override init() {
        super.init()
        setupCommandCenterCommands()
        player.addPeriodicTimeObserver(forInterval: CMTime(value: CMTimeValue(1), timescale: 2), queue: DispatchQueue.main) { [weak self] (progressTime) in
            self?.delegate?.updateProgress(progress: progressTime.seconds)
            self?.savedInfo?.currentTime = progressTime.seconds
            if let savedInfo = self?.savedInfo {
                try? self?.dataManager?.saveData(info: savedInfo)
            }
        }
    }
    
    func play(index: Int, updatesStorage: Bool? = false) {
        self.currentIndex = index
        if updatesStorage! {
            if isAlreadyRandomized {
                shuffleStorage(fromIndex: index)
            }
        }
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = true
        MPRemoteCommandCenter.shared().previousTrackCommand.isEnabled = true
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled = true
        
        guard let file = storage.value[self.currentIndex!] as? MediaFile else { return }
        
        guard let url = fileManager?.urls(for: .documentDirectory, in: .allDomainsMask).first?.appendingPathComponent(file.url) else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            let item = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: item)
            
            NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(note: )), name: .AVPlayerItemDidPlayToEndTime, object: item)
            
            
            let nowPlayingInfo = [String: Any]()
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            
            URLSession.shared.dataTask(with: (file.imageURL!)) { data, response, error in
                if error == nil {
                    let artwork = MPMediaItemArtwork(boundsSize: .zero) { (size) -> UIImage in
                        return UIImage(data: data!)!
                    }
                    
                    MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
                }
            }.resume()
            
            startRemoteCommandsCenter()
            player.rate = 1
            setBindings()
            delegate?.onItemChanged()
            NotificationCenter.default.post(name: NotificationCenterNames.playedSong, object: nil)
        } catch {
            delegate?.errorHandler(error: error)
        }
    }
    
    @objc private func playerDidFinishPlaying(note: NSNotification) {
        alreadyPlayed.append(currentFile!)
        playNext()
    }
    
    
    func playNext() {
        if currentIndex != nil {
            if currentIndex! + 1 <= storage.value.count - 1 {
                play(index: currentIndex! + 1)
            } else {
                play(index: 0)
                self.player.rate = isInLoop ? 1 : 0
            }
            delegate?.onItemChanged()
        }
    }
    
    func playPrevious() {
        if currentIndex != nil {
            if player.currentTime().seconds >= TimeInterval(3) {
                play(index: currentIndex!)
                return
            }
            
            if currentIndex! - 1 >= 0 {
                play(index: currentIndex! - 1)
            } else {
                play(index: storage.value.count - 1)
            }
            delegate?.onItemChanged()
        }
    }
    
    private func startRemoteCommandsCenter() {
        //LockScreen Media control registry
        if UIApplication.shared.responds(to: #selector(UIApplication.beginReceivingRemoteControlEvents)) {
            UIApplication.shared.beginReceivingRemoteControlEvents()
            UIApplication.shared.beginBackgroundTask(expirationHandler: { () -> Void in
            })
        }
    }
    
    private func setupCommandCenterCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [unowned self] event in
            if self.player.rate == 0 {
                continuePlay()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.player.rate == 1 {
                self.pause()
                return .success
            }
            return .commandFailed
        }
        
        
        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            playNext()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            playPrevious()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [unowned self] remoteEvent in
            if let seekEvent = remoteEvent as? MPChangePlaybackPositionCommandEvent {
                let time = CMTime(seconds: seekEvent.positionTime, preferredTimescale: 1000000)
                self.player.seek(to: time)
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = seekEvent.positionTime
                return .success
            }
            return .commandFailed
        }
    }
    
    func playTapped() {
        if currentFile != nil {
            if player.rate == 0 {
                continuePlay()
            } else {
                pause()
            }
        }
    }
    
    func pause() {
        player.rate = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentItem?.currentTime().seconds
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackProgress] = player.currentItem?.currentTime().seconds
    }
    
    func continuePlay() {
        player.rate = 1
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentItem?.currentTime().seconds
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackProgress] = player.currentItem?.currentTime().seconds
        
    }
    
    func seekTo(seconds: Double) {
        delegate?.isSeekInProgress = true
        let time = CMTime(seconds: seconds, preferredTimescale: 1000000)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] completed in
            self?.delegate?.isSeekInProgress = false
            MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time.seconds
        }
    }
    
    private func setBindings() {
        player.currentItem?.rx.status.subscribe { status in
            if status == .readyToPlay {
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = self.player.currentItem?.duration.seconds
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackProgress] = self.player.currentItem?.currentTime().seconds
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyTitle] = self.currentFile?.title
                
                if let storage = self.storage.value as? [MediaFile],
                   let unmodifiedStorage = self.unmodifiedStorage as? [MediaFile]?,
                   let item = self.player.currentItem {
                    self.savedInfo = PlayerInfo(storage: storage, unmodifiedStorage: unmodifiedStorage, currentIndex: self.currentIndex!, currentTime: item.currentTime().seconds, duration: item.duration.seconds, isRandomized: self.isAlreadyRandomized)
                }
            }
        }.disposed(by: disposeBag)
    }
    
    func randomize(fromIndex: Int) {
        if !isAlreadyRandomized {
            shuffleStorage(fromIndex: fromIndex)
        } else {
            if unmodifiedStorage != nil {
                currentIndex = unmodifiedStorage!.firstIndex(where: { $0.id == currentFile?.id })
                storage.accept(unmodifiedStorage!)
            }
        }
        isAlreadyRandomized = !isAlreadyRandomized
    }
    
    private func shuffleStorage(fromIndex: Int) {
        if storage.value.endIndex >= fromIndex {
            unmodifiedStorage = storage.value
            if fromIndex != storage.value.endIndex - 1 {
                let newStorage = (storage.value[0 ..< fromIndex] + storage.value[fromIndex + 1 ..< storage.value.count]).shuffled()
                storage.accept([storage.value[fromIndex]] + newStorage)
            } else {
                let shuffledPart = storage.value[0 ..< storage.value.count - 1].shuffled()
                storage.accept([storage.value[fromIndex]] + shuffledPart)
            }
            currentIndex = 0
        }
    }
}
