//
//  UIExtensions.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 31.03.2023.
//

import Foundation
import UIKit
import MarqueeLabel

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
