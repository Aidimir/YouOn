//
//  ShortedPlayerView.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 27.03.2023.
//

import Foundation
import UIKit
import SnapKit

class ShortedPlayerView: UIView {
    
    private enum Constants {
        static let actionButtonBoxSize = 50
    }
    
    var titleLabel: UILabel!
    var authorLabel: UILabel!
    var progressBar: UIProgressView!
    var actionButton = UIButton()
    let onActionButtonTapped: (() -> Void)?
    var buttonIcon: UIImage?
    
    init(currentTitle: String?,
         currentAuthor: String?,
         currentProgress: Float,
         buttonIcon: UIImage?,
         onActionButtonTapped: (() -> Void)?) {
        self.buttonIcon = buttonIcon
        self.onActionButtonTapped = onActionButtonTapped
        super.init(frame: .zero)
        addViews(currentTitle: currentTitle, currentAuthor: currentAuthor, currentProgress: currentProgress)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addViews(currentTitle: String?, currentAuthor: String?, currentProgress: Float) {
        titleLabel = .createScrollableLabel(fadeLength: 10, scrollingDuration: 6, animationDelay: 2)
        titleLabel.text = currentTitle
        titleLabel.textAlignment = .center
        
        authorLabel = .createScrollableLabel(fadeLength: 10, scrollingDuration: 6, animationDelay: 2)
        authorLabel.text = currentAuthor
        authorLabel.textColor = .gray
        authorLabel.textAlignment = .center
        
        progressBar = UIProgressView(progressViewStyle: .default)
        progressBar.tintColor = .white
        
        actionButton.tintColor = .white
        actionButton.addTarget(self, action: #selector(onButtonTapped), for: .touchUpInside)
        actionButton.setImage(buttonIcon, for: .normal)
        
        addSubview(progressBar)
        progressBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalToSuperview().dividedBy(20)
        }
        
        addSubview(actionButton)
        actionButton.snp.makeConstraints { make in
            make.right.centerY.equalToSuperview()
            make.width.height.equalTo(Constants.actionButtonBoxSize)
        }
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Constants.actionButtonBoxSize)
            make.right.equalTo(actionButton.snp.left)
            make.top.equalTo(progressBar.snp.bottom)
        }
        
        addSubview(authorLabel)
        authorLabel.snp.makeConstraints { make in
            make.left.right.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom)
        }
    }
    
    func updateValues(currentTitle: String?, currentAuthor: String?) {
        titleLabel.text = currentTitle
        authorLabel.text = currentAuthor
        actionButton.setImage(buttonIcon, for: .normal)
    }
    
    func updateProgress(progress: Float) {
        progressBar.progress = progress
    }
    
    @objc private func onButtonTapped() {
        onActionButtonTapped?()
    }
}
