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
        
        XCDYouTubeClient.default().getVideoWithIdentifier(linkString) { [weak self] video, error in
            onGotResponse?()
            guard let video = video, error == nil, let self = self else {
                if error != nil {
                    errorHandler?(error!)
                }
                
                return
            }
            
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
            
        /// TEMPORARY FIX ( CAUSE: XCDYouTubeKit IS BROKEN BECAUSE OF YOUTUBE API UPDATE
            if Array(video.streamURLs.values).count <= 1 || video.streamURL!.absoluteString.contains("manifest") {
                let errorTemp = NSError(domain: "Can't download any of audio or video streams", code: -1, userInfo: nil)
                if self.log[linkString]! < 100 {
                    self.log[linkString]! += 1
                    if self.log[linkString]! == 1 {
                        let err = NSError(domain: "Can't download video. Will try 100 times to do it.", code: -1, userInfo: nil)
                        errorHandler?(err)
                    }
                    self.downloadVideo(linkString: linkString, onGotResponse: onGotResponse, onCompleted: onCompleted, errorHandler: errorHandler)
                    return
                } else {
                    self.log[linkString] = 0
                    errorHandler?(errorTemp)
                    return
                }
            }
        /// REMOVE CODE ABOVE AFTER SOLUTION

            let downloadRequest = AF.request(video.streamURL!).downloadProgress(closure: { progress in
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
        }
    }
    
    func downloadAudio(linkString: String,
                       onCompleted: (() -> Void)?,
                       errorHandler: ((Error) -> Void)?) {
        //
    }
    
}
