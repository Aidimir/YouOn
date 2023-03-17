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
}

protocol MusicPlayerProtocol {
    var delegate: MusicPlayerDelegate? { get set }
    func play(file: MediaFile, onFinished: @escaping () -> Void)
    func pauseCurrent()
    func playCurrent()
}

class MusicPlayer: MusicPlayerProtocol {
    
    var delegate: MusicPlayerDelegate?
    
    private var player: AVAudioPlayer?
    
    func play(file: MediaFile, onFinished: @escaping () -> Void) {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first?.appendingPathComponent(file.url) else{ return }
        //guard let url = URL(string: musicFile.fullURL!) else {return}
        do {
            var nowPlayingInfo = [String : Any]()
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player!.currentTime
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player!.duration
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player!.rate
            nowPlayingInfo[MPMediaItemPropertyTitle] = file.title
            URLSession.shared.dataTask(with: (file.imgURL!)) {[weak self] data, response, error in
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
        } catch let error as NSError {
            print(error.description)
        }

    }
    
    func pauseCurrent() {
        player?.pause()
    }
    
    func playCurrent() {
        player?.play()
    }
    
    private func startRemoteCommandsCenter() {
        if UIApplication.shared.responds(to: #selector(UIApplication.beginReceivingRemoteControlEvents)){
            UIApplication.shared.beginReceivingRemoteControlEvents()
            UIApplication.shared.beginBackgroundTask(expirationHandler: { () -> Void in
            })
        }
        
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
            delegate?.onPlayNext()
            return .success
        }
        // Add handler for PreviousTack Command
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            delegate?.onPlayPrevious()
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
        //LockScreen Media control registry
        if UIApplication.shared.responds(to: #selector(UIApplication.beginReceivingRemoteControlEvents)) {
            UIApplication.shared.beginReceivingRemoteControlEvents()
            UIApplication.shared.beginBackgroundTask(expirationHandler: { () -> Void in
            })
        }

    }
    
}
