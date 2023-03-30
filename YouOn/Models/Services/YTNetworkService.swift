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
    
    var modelToStopDownloading: RxRelay.BehaviorRelay<DownloadModel?> = BehaviorRelay(value: nil)
    
    var nowInDownloading: BehaviorRelay<[DownloadModel]>  = BehaviorRelay(value: [DownloadModel]())
    
    private let fileManager: FileManager
    
    private let saver: MediaSaverProtocol
    
    required init(saver: MediaSaverProtocol, fileManager: FileManager) {
        self.saver = saver
        self.fileManager = fileManager
    }
    
    func downloadVideo(linkString: String,
                       onGotResponse: (() -> Void)?,
                       onCompleted: (() -> Void)?,
                       errorHandler: ((Error) -> Void)?) {
        
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
            
            let observableVal = BehaviorRelay(value: CGFloat(0))
            
            let downloadModel = DownloadModel(identity: video.identifier, title: video.title, link: linkString, progress: observableVal.asObservable())
            
            self.nowInDownloading.accept([downloadModel] + self.nowInDownloading.value)
            
            let fileName = "\(video.identifier).mp4"
            
            
            let mediaFile = MediaFile(url: fileName, title: video.title,
                                      id: video.identifier, duration: video.duration,
                                      author: video.author, videoURL: URL(string: linkString)!,
                                      imageURL: video.thumbnailURLs?.last)
            
            let downloadRequest = AF.request(video.streamURL!).downloadProgress(closure: { progress in
                observableVal.accept(progress.fractionCompleted)
            })
            
            self.modelToStopDownloading.asDriver().drive(onNext: { model in
                if downloadModel == model {
                    downloadRequest.cancel()
                    self.nowInDownloading.accept(self.nowInDownloading.value.filter({ $0.identity != video.identifier }))
                    return
                }
            }).disposed(by: self.disposeBag)

            downloadRequest.response(queue: .main) { response in
                if downloadRequest.isCancelled {
                    return
                }
                
                switch (response.result) {
                case .success(let data):
                    self.nowInDownloading.accept(self.nowInDownloading.value.filter({ $0.identity != video.identifier }))
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
