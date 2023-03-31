//
//  MediaFileAsHeaderView.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 31.03.2023.
//

import Foundation
import UIKit
import SnapKit

class MediaFileAsHeaderView: UIView {
    private var model: MediaFileUIProtocol
    private var imageCornerRadius: CGFloat
    
    init(model: MediaFileUIProtocol, imageCornerRadius: CGFloat = 10) {
        self.model = model
        self.imageCornerRadius = imageCornerRadius
        super.init(frame: .zero)
        addViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addViews() {
        let nameLabel = UILabel.createScrollableLabel(animationDelay: 4)
        nameLabel.text = model.title
        nameLabel.textColor = .white
        nameLabel.font = .boldSystemFont(ofSize: 20)
        
        let authorLabel = UILabel.createScrollableLabel(animationDelay: 2)
        authorLabel.text = model.author
        authorLabel.textColor = .gray
        authorLabel.font = .boldSystemFont(ofSize: 15)
        
        let durationLabel = UILabel()
        let duration = model.duration.stringTime
        durationLabel.text = duration
        durationLabel.textAlignment = .right
        durationLabel.textColor = .gray
        
        let imgView = UIImageView(image: nil)
        imgView.kf.setImage(with: model.imageURL)
        imgView.contentMode = .scaleToFill
        imgView.layer.cornerRadius = imageCornerRadius
        imgView.layer.masksToBounds = true
        
        addSubview(durationLabel)
        durationLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        addSubview(authorLabel)
        authorLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalTo(durationLabel.snp.left).inset(10)
            make.bottom.equalTo(durationLabel)
        }
        
        addSubview(imgView)
        imgView.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.5)
            make.width.equalTo(snp.height).multipliedBy(0.5)
        }
        
        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(imgView.snp.bottom).offset(20)
            make.right.equalTo(durationLabel.snp.left).offset(-10)
        }
        
        backgroundColor = .clear
    }
}
