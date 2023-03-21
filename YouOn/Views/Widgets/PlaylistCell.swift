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
    
    private var imgView: UIImageView!
    
    private var playlistTitle: UILabel!
    
    private var uiModel: PlaylistUIProtocol!
    
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
        self.uiModel = uiModel
        enum Constants {
            static let topPadding = 10
            static let bottomPadding = 10
            static let leftPadding = 10
            static let rightPadding = 10
        }
        
        imgView = {
           let imgView = UIImageView(image: nil)
            imgView.kf.setImage(with: uiModel.imageURL, placeholder: placeholder)
            imgView.contentMode = .scaleAspectFill
            imgView.layer.cornerRadius = cornerRadius
            imgView.tintColor = .gray
            imgView.clipsToBounds = true
            return imgView
        }()
        
        playlistTitle = {
           let label = UILabel()
            label.text = uiModel.title
            label.textColor = .white
            label.font = .boldSystemFont(ofSize: 30)
            label.textAlignment = .center
            return label
        }()
        
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
            make.centerY.equalToSuperview()
        }
        
        addSubview(view)
        view.frame = contentView.bounds
        contentView.backgroundColor = backgroundColor
    }
}

