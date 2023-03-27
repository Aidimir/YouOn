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
        titleLabel = .createScrollableLabel()
        titleLabel.text = currentTitle
        titleLabel.textAlignment = .center
        
        authorLabel = .createScrollableLabel()
        authorLabel.text = currentAuthor
        authorLabel.textColor = .darkGray
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
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(progressBar.snp.bottom)
        }
        
        addSubview(authorLabel)
        authorLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom)
        }
        
        addSubview(actionButton)
        actionButton.snp.makeConstraints { make in
            make.right.centerY.equalToSuperview()
            make.width.height.equalTo(50)
        }
    }
    
    func updateValues(currentTitle: String?, currentAuthor: String?, currentProgress: Float) {
        titleLabel.text = currentTitle
        authorLabel.text = currentAuthor
        progressBar.progress = currentProgress
        actionButton.setImage(buttonIcon, for: .normal)
    }
    
    @objc private func onButtonTapped() {
        onActionButtonTapped?()
    }
}
