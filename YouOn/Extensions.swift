//
//  Extensions.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 15.03.2023.
//

import Foundation
import UIKit
import RxRelay
import RxCocoa
import RxSwift
import MarqueeLabel
import AVFAudio
import AVFoundation
import MediaPlayer

extension String {
    func getYoutubeID() -> String? {
        let pattern = #"(?<=v(=|/))([-a-zA-Z0-9_]+)|(?<=youtu.be/)([-a-zA-Z0-9_]+)"#
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

extension UIView {
    func getCurrentViewController() -> UIViewController? {
        if let rootController = UIApplication.shared.keyWindow?.rootViewController {
            var currentController: UIViewController! = rootController
            while( currentController.presentedViewController != nil ) {
                currentController = currentController.presentedViewController
            }
            return currentController
        }
        return nil
    }
}

extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    
    func setRightPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}

extension UIColor {
    static let darkGray = UIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1)
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

extension UIViewController {
    func showInputDialog(title: String? = nil,
                         subtitle: String? = nil,
                         actionTitle: String? = "Add",
                         cancelTitle: String? = "Cancel",
                         inputPlaceholder: String? = nil,
                         inputKeyboardType: UIKeyboardType = UIKeyboardType.default,
                         cancelHandler: ((UIAlertAction) -> Void)? = nil,
                         actionHandler: ((_ text: String?) -> Void)? = nil) {
        
        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        alert.addTextField { (textField:UITextField) in
            textField.placeholder = inputPlaceholder
            textField.keyboardType = inputKeyboardType
        }
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { (action:UIAlertAction) in
            guard let textField =  alert.textFields?.first else {
                actionHandler?(nil)
                return
            }
            actionHandler?(textField.text)
        }))
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: cancelHandler))
        
        self.present(alert, animated: true, completion: nil)
    }
}

extension UIFont {
    public static let titleFont = UIFont.systemFont(ofSize: 24, weight: .semibold)
    
    public static let mediumSizeBoldFont = UIFont.systemFont(ofSize: 20, weight: .semibold)
    
    public static let mediumSizeFont = UIFont.systemFont(ofSize: 20, weight: .medium)
    
    public static let smallSizeFont = UIFont.systemFont(ofSize: 15, weight: .medium)
}

extension UILabel {
    static func createScrollableLabel(fadeLength: CGFloat = 20,
                                      scrollingDuration: CGFloat = 6,
                                      animationDelay: CGFloat = 2) -> UILabel {
        let label = MarqueeLabel(frame: .zero, duration: scrollingDuration, fadeLength: 0)
        label.animationDelay = animationDelay
        label.fadeLength = fadeLength
        label.textColor = .white
        label.font = .mediumSizeBoldFont
        return label
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
        return self.observe(Bool.self, #keyPath(AVPlayer.rate))
            .map({ $0 ?? false })
    }
    
    public var currentDuration: Observable<Double?> {
        return self.observe(CMTime.self, #keyPath(AVPlayer.currentItem.duration))
            .map({ $0?.seconds })
    }
}
