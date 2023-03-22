//
//  PlaylistCell.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 20.03.2023.
//

import Foundation
import UIKit
import Kingfisher
import SnapKit

class PlaylistCell: UITableViewCell {
    
    private let placeholder = UIImage(systemName: "music.note.list")
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isUserInteractionEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setup(uiModel: PlaylistUIProtocol, foregroundColor: UIColor,
                      backgroundColor: UIColor, cornerRadius: CGFloat = 0) {
        enum Constants {
            static let topPadding = 10
            static let bottomPadding = 10
            static let leftPadding = 10
            static let rightPadding = 10
        }
        
        let imgView = UIImageView()
        imgView.kf.setImage(with: uiModel.imageURL, placeholder: placeholder)
        imgView.contentMode = .scaleAspectFill
        imgView.layer.cornerRadius = cornerRadius
        imgView.tintColor = .gray
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

        let view = UIView()
        view.backgroundColor = foregroundColor
        
        view.addSubview(imgView)
        imgView.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.4)
            make.height.equalToSuperview()
            make.left.equalToSuperview()
        }
        
        view.addSubview(playlistTitle)
        playlistTitle.snp.makeConstraints { make in
            make.left.equalTo(imgView.snp.right).offset(Constants.leftPadding)
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(view.snp.centerY)
        }
        
        view.addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.top.equalTo(playlistTitle.snp.bottom)
            make.left.equalTo(imgView.snp.right)
            make.right.equalToSuperview()
        }
        
        addSubview(view)
        view.frame = contentView.bounds
        contentView.backgroundColor = backgroundColor
    }
}
