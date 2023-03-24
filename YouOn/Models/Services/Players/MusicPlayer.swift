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

protocol MusicPlayerDelegate {
    func onPlayNext()
    func onPlayPrevious()
    func errorHandler(error: Error)
}

protocol MusicPlayerProtocol {
    var delegate: MusicPlayerDelegate? { get set }
    var storage: [MediaFile] { get set }
    var fileManager: FileManager? { get set }
    func playNext()
    func playPrevious()
    func play(index: Int)
}

class MusicPlayer: NSObject, MusicPlayerProtocol, AVAudioPlayerDelegate {
    
    var fileManager: FileManager?
    
    var storage: [MediaFile] = []
    
    var delegate: MusicPlayerDelegate?
    
    private var index: Int?
    
    private var player: AVAudioPlayer?
    
    override init() {
        super.init()
        setupCommandCenterCommands()
    }
    
    func play(index: Int) {
        self.index = index
        let file = storage[self.index!]
        
        guard let url = fileManager?.urls(for: .documentDirectory, in: .allDomainsMask).first?.appendingPathComponent(file.url) else { return }
        do {
            var nowPlayingInfo = [String : Any]()
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player!.currentTime
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player!.duration
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player!.rate
            nowPlayingInfo[MPMediaItemPropertyTitle] = file.title
            URLSession.shared.dataTask(with: (file.imageURL!)) {[weak self] data, response, error in
                if error == nil {
                    let artwork = MPMediaItemArtwork(boundsSize: .zero) { (size) -> UIImage in
                        return UIImage(data: data!)!
                    }
                    
                    MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
                    
                    MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self?.player!.currentTime
                    
                    MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self?.player!.currentTime
                }
            }.resume()
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            startRemoteCommandsCenter()
            //            player!.delegate = self
            player!.play()
        } catch {
            delegate?.errorHandler(error: error)
        }
    }
    
    internal func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playNext()
    }
    
    func playNext() {
        if index != nil {
            if index! + 1 <= storage.count - 1 {
                play(index: index! + 1)
            } else {
                play(index: 0)
                self.player?.pause()
            }
        }
    }
    
    func playPrevious() {
        if index != nil {
            if player!.currentTime >= TimeInterval(3) {
                play(index: index!)
                return
            }
            
            if index! - 1 >= 0 {
                play(index: index! - 1)
            } else {
                play(index: storage.count - 1)
            }
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
            if self.player != nil {
                if !self.player!.isPlaying{
                    self.player!.play()
                    MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player!.currentTime
                    return .success
                }
            }
            return .commandFailed
        }
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.player != nil {
                if self.player!.isPlaying {
                    self.player!.pause()
                    return .success
                }
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
                if player != nil {
                    self.player!.currentTime = seekEvent.positionTime
                    MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = seekEvent.positionTime
                }
                return .success
            }
            return .commandFailed
        }
    }
}
