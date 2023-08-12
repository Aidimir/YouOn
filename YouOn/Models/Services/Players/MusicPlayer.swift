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
    func removeControlCenterCommands()
    var isInLoop: Bool { get set }
    var isAlreadyRandomized: Bool { get }
}

protocol MusicPlayerStorageProtocol: AnyObject {
    func randomize(fromIndex: Int)
    func addNext(file: MediaFile)
    func addLast(file: MediaFile)
    var storage: BehaviorRelay<[MediaFileUIProtocol]> { get }
    var currentFile: BehaviorRelay<MediaFileUIProtocol?> { get }
}

protocol PlayerStatusProtocol: AnyObject {
    var isPlaying: Observable<Bool> { get }
}

typealias OutsidePlayerControlProtocol = MusicPlayerStorageProtocol & MusicPlayerControlProtocol & PlayerStatusProtocol

protocol MusicPlayerProtocol: AnyObject, OutsidePlayerControlProtocol {
    func fetchActionModels(indexPath: IndexPath) -> [ActionModel]
    func updateOnUiChanges()
    var dataManager: PlayerDataManagerProtocol? { get set }
    var currentIndex: BehaviorRelay<Int?> { get }
    var currentItemDuration: Observable<Double?> { get }
    var delegate: MusicPlayerViewDelegate? { get set }
    var fileManager: FileManager? { get set }
}

class MusicPlayer: NSObject, MusicPlayerProtocol, MusicPlayerControlProtocol {
    
    private var remotePlayCommand: Any?
    
    private var remotePauseCommand: Any?
    
    private var remoteChangePlaybackPosCommand: Any?
    
    private var remoteNextTrackCommand: Any?
    
    private var remotePreviousTrackCommand: Any?
    
    func updateOnUiChanges() {
        currentIndex.accept(storage.value.firstIndex(where: { model in
            if let id = currentFile.value?.playlistSpecID {
                return id == model.playlistSpecID
            } else {
                return currentFile.value?.id == model.id
            }
        }))
    }
    
    
    var currentFile: BehaviorRelay<MediaFileUIProtocol?> = BehaviorRelay(value: nil)
    
    func fetchActionModels(indexPath: IndexPath) -> [ActionModel] {
        var actions = [ActionModel]()
        
        if let item = storage.value[indexPath.row] as? MediaFile, let storage = self.storage.value as? [MediaFile] {
            let playNextAction = ActionModel(title: "Play next", onTap: {
                self.addNext(file: item)
            }, iconName: "text.insert")
            actions.append(playNextAction)
            
            let playLastAction = ActionModel(title: "Add to queue", onTap: {
                self.addLast(file: item)
            }, iconName: "text.append")
            actions.append(playLastAction)
            
            let removeAction = ActionModel(title: "Remove", onTap: {
                self.storage.removeElement(at: indexPath.row)
            }, iconName: "trash")
            actions.append(removeAction)
        }
        
        return actions
    }
    
    
    var isInLoop: Bool = false
    
    var storage: RxRelay.BehaviorRelay<[MediaFileUIProtocol]> = BehaviorRelay(value: [])
    
    private var unmodifiedStorage: [MediaFileUIProtocol]? = nil
    
    private var savedInfo: PlayerInfo?
    
    var dataManager: PlayerDataManagerProtocol? {
        didSet {
            let info = try? dataManager?.fetchSavedData()
            savedInfo = info
            if info != nil {
                currentIndex.accept(savedInfo!.currentIndex)
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
    
    var fileManager: FileManager?
    
    weak var delegate: MusicPlayerViewDelegate?
    
    var currentIndex: BehaviorRelay<Int?> = BehaviorRelay(value: nil)
    
    var isAlreadyRandomized: Bool = false
    
    private var player: AVPlayer = AVPlayer()
    
    private let disposeBag = DisposeBag()
    
    static let shared = MusicPlayer()
    
    override init() {
        super.init()
        startRemoteControlCenter()
        player.addPeriodicTimeObserver(forInterval: CMTime(value: CMTimeValue(1), timescale: 2), queue: DispatchQueue.main) { [weak self] (progressTime) in
            self?.delegate?.updateProgress(progress: progressTime.seconds)
            self?.savedInfo?.currentTime = progressTime.seconds
            if let storage = self?.storage.value as? [MediaFile] {
                self?.savedInfo?.storage = storage
            }
            
            if let savedInfo = self?.savedInfo {
                try? self?.dataManager?.saveData(info: savedInfo)
            }
        }
    }
    
    func play(index: Int, updatesStorage: Bool? = false) {
        currentIndex.accept(index)
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
        
        guard let file = storage.value[currentIndex.value!] as? MediaFile else { return }
        
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
            
            startRemoteControlCenter()
            player.rate = 1
            setBindings()
            NotificationCenter.default.post(name: NotificationCenterNames.playedSong, object: nil)
        } catch {
            delegate?.errorHandler(error: error)
        }
    }
    
    @objc private func playerDidFinishPlaying(note: NSNotification) {
        playNext()
    }
    
    
    func playNext() {
        if currentIndex.value != nil {
            if currentIndex.value! + 1 <= storage.value.count - 1 {
                play(index: currentIndex.value! + 1)
            } else {
                play(index: 0)
                player.rate = isInLoop ? 1 : 0
            }
        }
    }
    
    func playPrevious() {
        if currentIndex.value != nil {
            if player.currentTime().seconds >= TimeInterval(3) {
                play(index: currentIndex.value!)
                return
            }
            
            if currentIndex.value! - 1 >= 0 {
                play(index: currentIndex.value! - 1)
            } else {
                play(index: storage.value.count - 1)
            }
        }
    }
    
    private func startRemoteControlCenter() {
        //LockScreen Media control registry
        removeControlCenterCommands()
        if UIApplication.shared.responds(to: #selector(UIApplication.beginReceivingRemoteControlEvents)) {
            UIApplication.shared.beginReceivingRemoteControlEvents()
            setupControlCenterCommands()
            UIApplication.shared.beginBackgroundTask(expirationHandler: { () -> Void in
            })
        }
    }
    
    private func setupControlCenterCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        remotePlayCommand = commandCenter.playCommand.addTarget { [unowned self] event in
            if self.player.rate == 0 {
                continuePlay()
                return .success
            }
            return .commandFailed
        }
        
        remotePauseCommand = commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.player.rate == 1 {
                self.pause()
                return .success
            }
            return .commandFailed
        }
        
        
        remoteNextTrackCommand = commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            playNext()
            return .success
        }
        
        remotePreviousTrackCommand = commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            playPrevious()
            return .success
        }
        
        remoteChangePlaybackPosCommand = commandCenter.changePlaybackPositionCommand.addTarget { [unowned self] remoteEvent in
            if let seekEvent = remoteEvent as? MPChangePlaybackPositionCommandEvent {
                let time = CMTime(seconds: seekEvent.positionTime, preferredTimescale: 1000000)
                self.player.seek(to: time)
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = seekEvent.positionTime
                return .success
            }
            return .commandFailed
        }
    }
    
    func removeControlCenterCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(remotePlayCommand)
        commandCenter.pauseCommand.removeTarget(remotePauseCommand)
        commandCenter.nextTrackCommand.removeTarget(remoteNextTrackCommand)
        commandCenter.previousTrackCommand.removeTarget(remotePreviousTrackCommand)
        commandCenter.changePlaybackPositionCommand.removeTarget(remoteChangePlaybackPosCommand)
        
        remotePlayCommand = nil
        remotePauseCommand = nil
        remoteNextTrackCommand = nil
        remotePreviousTrackCommand = nil
        remoteChangePlaybackPosCommand = nil
    }
    
    func playTapped() {
        if currentFile.value != nil {
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
        
        if remotePlayCommand == nil || remoteChangePlaybackPosCommand == nil {
            startRemoteControlCenter()
        }
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
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyTitle] = self.currentFile.value?.title
                
                if let storage = self.storage.value as? [MediaFile],
                   let unmodifiedStorage = self.unmodifiedStorage as? [MediaFile]?,
                   let item = self.player.currentItem {
                    self.savedInfo = PlayerInfo(storage: storage, unmodifiedStorage: unmodifiedStorage, currentIndex: self.currentIndex.value!, currentTime: item.currentTime().seconds, duration: item.duration.seconds, isRandomized: self.isAlreadyRandomized)
                }
            }
        }.disposed(by: disposeBag)
        
        storage.subscribe { val in
            if let storage = val.element as? [MediaFile], var info = self.savedInfo {
                info.storage = storage
                try? self.dataManager?.saveData(info: info)
            }
        }.disposed(by: disposeBag)
        
        currentIndex.subscribe { [weak self] index in
            if index != nil {
                self?.currentFile.accept(self?.storage.value[index!])
            }
        }.disposed(by: disposeBag)
    }
    
    func randomize(fromIndex: Int) {
        if !isAlreadyRandomized {
            shuffleStorage(fromIndex: fromIndex)
        } else {
            if unmodifiedStorage != nil {
                storage.accept(unmodifiedStorage!)
                currentIndex.accept(unmodifiedStorage!.firstIndex(where: { $0.id == currentFile.value?.id }))
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
            currentIndex.accept(0)
        }
    }
    
    func addNext(file: MediaFile) {
        if currentIndex.value != nil {
            var newStorage = storage.value
            var fileNewId = file
            fileNewId.playerSpecID = UUID()
            newStorage.insert(fileNewId, at: currentIndex.value! + 1)
            storage.accept(newStorage)
        }
    }
    
    func addLast(file: MediaFile) {
        var fileNewId = file
        fileNewId.playerSpecID = UUID()
        storage.accept(storage.value + [fileNewId])
    }
}
