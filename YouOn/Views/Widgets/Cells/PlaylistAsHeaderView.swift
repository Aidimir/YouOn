//
//  PlaylistAsHeaderView.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 31.03.2023.
//

import Foundation
import UIKit
import SnapKit

class PlaylistAsHeaderView: UIView {
    init(uiModel: PlaylistUIProtocol, backgroundColor: UIColor, cornerRadius: CGFloat = 0) {
        enum Constants {
            static let verticalPadding = 10
            static let horizontalPadding = 10
        }
        
        super.init(frame: .zero)
        
        let imgView = UIImageView()
        imgView.kf.setImage(with: uiModel.imageURL)
        imgView.contentMode = .scaleAspectFill
        imgView.layer.cornerRadius = cornerRadius
        imgView.tintColor = .gray
        imgView.layer.cornerRadius = 10
        imgView.clipsToBounds = true
        
        let playlistTitle = UILabel()
        playlistTitle.text = uiModel.title
        playlistTitle.textColor = .white
        playlistTitle.font = .boldSystemFont(ofSize: 30)
        playlistTitle.textAlignment = .center
        
        let countLabel = UILabel()
        countLabel.text = uiModel.tracksCountString
        countLabel.textColor = .gray
        countLabel.font = .boldSystemFont(ofSize: 20)
        countLabel.textAlignment = .center
        
        addSubview(imgView)
        imgView.snp.makeConstraints { make in
            make.height.equalToSuperview()
            make.width.equalTo(snp.height)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
        }
        
        addSubview(playlistTitle)
        playlistTitle.snp.makeConstraints { make in
            make.left.equalTo(imgView.snp.right).offset(Constants.horizontalPadding)
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(self.snp.centerY)
        }
        
        addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.top.equalTo(playlistTitle.snp.bottom)
            make.left.equalTo(imgView.snp.right)
            make.right.equalToSuperview()
        }
        
        self.backgroundColor = backgroundColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
