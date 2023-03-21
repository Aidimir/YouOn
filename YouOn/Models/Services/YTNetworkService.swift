//
//  YTNetworkService.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 15.03.2023.
//

import Foundation
import XCDYouTubeKit
import Alamofire

protocol YTNetworkServiceProtocol {
    var saver: MediaSaverProtocol? { get set }
    func downloadVideo(linkString: String, completion: ((_ progress: Double) -> Void)?,
                       onCompleted: (() -> Void)?,
                       errorHandler: ((Error) -> Void)?)
    func downloadAudio(linkString: String, completion: ((_ progress: Double) -> Void)?,
                       onCompleted: (() -> Void)?,
                       errorHandler: ((Error) -> Void)?)
}

class YTNetworkService: YTNetworkServiceProtocol {
    
    var saver: MediaSaverProtocol?
    
    func downloadVideo(linkString: String, completion: ((Double) -> Void)?,
                       onCompleted: (() -> Void)?,
                       errorHandler: ((Error) -> Void)?) {
        let manager = FileManager.default
        
        guard let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        XCDYouTubeClient.default().getVideoWithIdentifier(linkString.getYoutubeID()) { video, error in
            guard let video = video, error == nil else {
                if error != nil {
                    errorHandler?(error!)
                }
                
                return
            }
            
            let fileName = "\(video.identifier).mp4"
            
            let mediaFile = MediaFile(url: fileName, title: video.title,
                                      id: video.identifier, duration: video.duration,
                                      author: video.author, videoURL: URL(string: linkString)!,
                                      imageURL: video.thumbnailURLs?.first)
            do {
                if manager.fileExists(atPath: url.appendingPathComponent(fileName).path) {
                    try manager.removeItem(at: url.appendingPathComponent(fileName))
                }
                
                AF.request(video.streamURL!).downloadProgress(closure: { progress in
                    completion?(progress.fractionCompleted)
                }).response(queue: .global()) { response in
                    switch (response.result) {
                    case .success(let data):
                        manager.createFile(atPath: url.appendingPathComponent(fileName).path, contents: data)
                        try? self.saver?.saveToAll(file: mediaFile)
                        onCompleted?()
                    case .failure(let error):
                        errorHandler?(error)
                        return
                    }
                }
            } catch {
                errorHandler?(error)
                return
            }
        }
    }
    
    func downloadAudio(linkString: String, completion: ((Double) -> Void)?,
                       onCompleted: (() -> Void)?,
                       errorHandler: ((Error) -> Void)?) {
//        
    }
    
}
