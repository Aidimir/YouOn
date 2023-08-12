//
//  Extensions.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 15.03.2023.
//

import Foundation
import RxRelay
import RxCocoa
import RxSwift
import AVFAudio
import AVFoundation
import MediaPlayer

extension String {
    func getYoutubeID() -> String? {
        let pattern = #"(?<=v(=|/))([-a-zA-Z0-9_]+)|(?<=youtu.be/)([-a-zA-Z0-9_]+)|(?<=youtube.com/shorts/)([-a-zA-Z0-9_]+)"#
        if let matchRange = self.range(of: pattern, options: .regularExpression) {
            return String(self[matchRange])
        } else {
            return .none
        }
    }
}

extension Encodable {
    func saveAsJsonData() -> Data? {
        do {
            let encoded = try JSONEncoder().encode(self)
            return encoded
        } catch {
            return nil
        }
    }
}

extension TimeInterval {
    private var milliseconds: Int {
        return Int((truncatingRemainder(dividingBy: 1)) * 1000)
    }
    
    private var seconds: Int {
        return Int(self) % 60
    }
    
    private var minutes: Int {
        return (Int(self) / 60 ) % 60
    }
    
    private var hours: Int {
        return Int(self) / 3600
    }
    
    var stringTime: String {
        if hours != 0 {
            return "\(hours)h \(minutes):\(seconds)s"
        } else if minutes != 0 {
            if seconds < 10 {
                return "\(minutes):0\(seconds)"
            }
            return "\(minutes):\(seconds)"
        } else {
            if seconds < 10 {
                return "0:0\(seconds)"
            }
            return "0:\(seconds)"
        }
    }
}

extension BehaviorRelay where Element: RangeReplaceableCollection {
    func replaceElement(at index: Element.Index, insertTo insertIndex: Element.Index, with element: Element.Element) {
        var newValue = value
        newValue.remove(at: index)
        newValue.insert(element, at: insertIndex)
        accept(newValue)
    }
    
    func removeElement(at index: Element.Index) {
        var newValue = value
        newValue.remove(at: index)
        accept(newValue)
    }
}

extension Reactive where Base: AVPlayer {
    public var status: Observable<AVPlayer.Status> {
        return self.observe(AVPlayer.Status.self, #keyPath(AVPlayer.status))
            .map { $0 ?? .unknown }
    }
}

extension Reactive where Base: AVPlayerItem {
    public var status: Observable<AVPlayerItem.Status> {
        return self.observe(AVPlayerItem.Status.self, #keyPath(AVPlayerItem.status))
            .map { $0 ?? .unknown }
    }
}

extension Reactive where Base: AVPlayer {
    public var isPlaying: Observable<Bool> {
        return self.observe(Float.self, #keyPath(AVPlayer.rate)).map({ $0 == 1 })
    }
    
    public var currentDuration: Observable<Double?> {
        return self.observe(CMTime.self, #keyPath(AVPlayer.currentItem.duration))
            .map({ $0?.seconds })
    }
}
