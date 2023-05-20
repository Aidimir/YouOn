//
//  YTNetworkService.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 15.03.2023.
//

import Foundation
import XCDYouTubeKit
import Alamofire
import RxRelay
import RxSwift
import YouTubeKit

protocol YTNetworkServiceProtocol: AnyObject {
    init(saver: MediaSaverProtocol, fileManager: FileManager)
    var nowInDownloading: BehaviorRelay<[DownloadModel]> { get }
    var modelToStopDownloading: BehaviorRelay<DownloadModel?> { get }
    func downloadVideo(linkString: String,
                       onGotResponse: (() -> Void)?,
                       onCompleted: (() -> Void)?,
                       errorHandler: ((Error) -> Void)?)
    func downloadAudio(linkString: String,
                       onCompleted: (() -> Void)?,
                       errorHandler: ((Error) -> Void)?)
}

class YTNetworkService: YTNetworkServiceProtocol {
    
    private let disposeBag = DisposeBag()
    
    private var log: Dictionary<String, Int> = [:]
    
    var modelToStopDownloading: RxRelay.BehaviorRelay<DownloadModel?> = BehaviorRelay(value: nil)
    
    var nowInDownloading: BehaviorRelay<[DownloadModel]>  = BehaviorRelay(value: [DownloadModel]())
    
    private let fileManager: FileManager
    
    private let saver: MediaSaverProtocol
    
    required init(saver: MediaSaverProtocol, fileManager: FileManager) {
        self.saver = saver
        self.fileManager = fileManager
        modelToStopDownloading.asObservable().subscribe(onNext: { [unowned self] model in
            model?.dataRequest.cancel()
            self.nowInDownloading.accept(self.nowInDownloading.value.filter({ $0.dataRequest != model?.dataRequest }))
            return
        }).disposed(by: disposeBag)
    }
    
    func downloadVideo(linkString: String,
                       onGotResponse: (() -> Void)?,
                       onCompleted: (() -> Void)?,
                       errorHandler: ((Error) -> Void)?) {
        
        if log[linkString] == nil {
            log[linkString] = 0
        }
        
        guard let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            let errorTemp = NSError(domain: "Couldn't fetch file's url", code: -1, userInfo: nil)
            errorHandler?(errorTemp)
            return
        }
        
        fetchVideoInfo(linkString: linkString, onCompleted: { video in
            if self.nowInDownloading.value.contains(where: { $0.identity == video.identifier }) {
                let errorTemp = NSError(domain: "This video is already downloading !", code: -1, userInfo: nil)
                errorHandler?(errorTemp)
                return
            }
            
            let fileName = "\(video.identifier).mp4"
            
            
            let mediaFile = MediaFile(url: fileName, title: video.title,
                                      id: video.identifier, duration: video.duration,
                                      author: video.author, videoURL: URL(string: linkString)!,
                                      supportsVideo: true,
                                      imageURL: video.thumbnailURLs?.last)
            
            let observableVal = BehaviorRelay(value: CGFloat(0))
            
            Task {
                do {
                    let streamURL = try await YouTube(videoID: linkString).streams
                                              .filter { $0.isProgressive && $0.subtype == "mp4" }
                                              .highestResolutionStream()?
                                              .url
                    if streamURL == nil {
                        let err = NSError(domain: "Can't download any of \"\(video.title)\" streams.", code: -1, userInfo: nil)
                        errorHandler?(err)
                        return
                    }
                    DispatchQueue.main.async {
                        onGotResponse?()
                    }
                    let downloadRequest = AF.request(streamURL!).downloadProgress(closure: { progress in
                        observableVal.accept(progress.fractionCompleted)
                    })
                    
                    let downloadModel = DownloadModel(identity: video.identifier, title: video.title, link: linkString, progress: observableVal.asObservable(), dataRequest: downloadRequest)
                    
                    self.nowInDownloading.accept([downloadModel] + self.nowInDownloading.value)
                    
                    downloadRequest.response(queue: .main) { response in
                        if downloadRequest.isCancelled {
                            self.modelToStopDownloading.accept(nil)
                            return
                        }
                        
                        switch (response.result) {
                        case .success(let data):
                            self.nowInDownloading.accept(self.nowInDownloading.value.filter({ $0.dataRequest != downloadRequest }) )
                            do {
                                if self.fileManager.fileExists(atPath: url.appendingPathComponent(fileName).path) {
                                    try self.fileManager.removeItem(at: url.appendingPathComponent(fileName))
                                }
                            } catch {
                                errorHandler?(error)
                            }
                            self.fileManager.createFile(atPath: url.appendingPathComponent(fileName).path, contents: data)
                            try? self.saver.saveToAll(file: mediaFile)
                            onCompleted?()
                        case .failure(let error):
                            errorHandler?(error)
                            downloadModel.dataRequest.cancel()
                            self.nowInDownloading.accept(self.nowInDownloading.value.filter({ $0.dataRequest != downloadModel.dataRequest }))
                            return
                        }
                    }
                } catch {
                    errorHandler?(error)
                }
            }
        }, errorHandler: errorHandler)
    }
    
    func downloadAudio(linkString: String,
                       onCompleted: (() -> Void)?,
                       errorHandler: ((Error) -> Void)?) {
        //
    }
    
    private func fetchVideoInfo(linkString: String,
                                onCompleted: ((_ video: XCDYouTubeVideo) -> Void)?,
                                errorHandler: ((Error) -> Void)?) {
        
        XCDYouTubeClient.default().getVideoWithIdentifier(linkString) { [weak self] video, error in
            guard let video = video, error == nil, let self = self else {
                if error != nil {
                    errorHandler?(error!)
                }
                
                return
            }
            onCompleted?(video)
        }
    }
}
