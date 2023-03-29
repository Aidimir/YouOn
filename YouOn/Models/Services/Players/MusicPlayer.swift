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

protocol MusicPlayerViewDelegate {
    var isScrubbingFlag: Bool { get set }
    var isSeekInProgress: Bool { get set }
    func onItemChanged()
    func updateDuration(duration: Double)
    func updateProgress(progress: Double)
    func errorHandler(error: Error)
}

protocol MusicPlayerProtocol {
    var dataManager: PlayerDataManagerProtocol? { get set }
    var currentFile: MediaFileUIProtocol? { get }
    var isPlaying: Observable<Bool> { get }
    var currentItemDuration: Observable<Double?> { get }
    var delegate: MusicPlayerViewDelegate? { get set }
    var storage: [MediaFileUIProtocol] { get set }
    var fileManager: FileManager? { get set }
    func seekTo(seconds: Double)
    func playNext()
    func playPrevious()
    func play(index: Int)
    func playTapped()
    func pause()
    func continuePlay()
}

class MusicPlayer: NSObject, MusicPlayerProtocol {
    
    private var savedInfo: PlayerInfo?
    
    var dataManager: PlayerDataManagerProtocol? {
        didSet {
            let info = try? dataManager?.fetchSavedData()
            savedInfo = info
            if info != nil {
                index = savedInfo!.currentIndex
                storage = savedInfo!.storage
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
            if index != nil {
                return storage[index!]
            }
            return nil
        }
    }
    
    var fileManager: FileManager?
    
    var storage: [MediaFileUIProtocol] = []
    
    var delegate: MusicPlayerViewDelegate?
    
    private var index: Int?
    
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
    
    func play(index: Int) {
        self.index = index
        guard let file = storage[self.index!] as? MediaFile, let storage = storage as? [MediaFile] else { return }
        
        guard let url = fileManager?.urls(for: .documentDirectory, in: .allDomainsMask).first?.appendingPathComponent(file.url) else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            let item = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: item)
            
            NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(note: )), name: .AVPlayerItemDidPlayToEndTime, object: item)
            
            
            var nowPlayingInfo = [String: Any]()
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            
            URLSession.shared.dataTask(with: (file.imageURL!)) { [weak self] data, response, error in
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
        playNext()
    }
    
    
    func playNext() {
        if index != nil {
            if index! + 1 <= storage.count - 1 {
                play(index: index! + 1)
            } else {
                play(index: 0)
                self.player.rate = 0
            }
            delegate?.onItemChanged()
        }
    }
    
    func playPrevious() {
        if index != nil {
            if player.currentTime().seconds >= TimeInterval(3) {
                play(index: index!)
                return
            }
            
            if index! - 1 >= 0 {
                play(index: index! - 1)
            } else {
                play(index: storage.count - 1)
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
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            if self.player.rate == 0 {
                self.player.rate = 1
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentTime
                return .success
            }
            return .commandFailed
        }
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.player.rate == 1 {
                self.player.rate = 0
                return .success
            }
            return .commandFailed
        }
        
        // Add handler for NextTrack Command
        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            playNext()
            return .success
        }
        // Add handler for PreviousTack Command
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
                player.rate = 1
            } else {
                player.rate = 0
            }
        }
    }
    
    func pause() {
        player.rate = 0
    }
    
    func continuePlay() {
        player.rate = 1
    }
    
    func seekTo(seconds: Double) {
        delegate?.isSeekInProgress = true
        let time = CMTime(seconds: seconds, preferredTimescale: 1000000)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] completed in
            self?.delegate?.isSeekInProgress = false
        }
    }
    
    private func setBindings() {
        player.currentItem?.rx.status.subscribe { status in
            if status == .readyToPlay {
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentItem?.currentTime().seconds
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = self.player.currentItem?.duration.seconds
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentItem?.currentTime()
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyTitle] = self.currentFile?.title
                
                if let storage = self.storage as? [MediaFile],
                   let item = self.player.currentItem {
                    self.savedInfo = PlayerInfo(storage: storage , currentIndex: self.index!, currentTime: item.currentTime().seconds, duration: item.duration.seconds)
                }
            }
        }.disposed(by: disposeBag)
    }
}
