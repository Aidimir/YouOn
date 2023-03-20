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
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isUserInteractionEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setup(uiModel: PlaylistUIProtocol) {
        let imgView: UIImageView = {
           let imgView = UIImageView(image: nil)
            imgView.kf.setImage(with: uiModel.imageURL)
            imgView.contentMode = .scaleAspectFit
            return imgView
        }()
        
        let playlistTitle: UILabel = {
           let label = UILabel()
            label.text = uiModel.title
            label.textColor = .white
            label.font = .boldSystemFont(ofSize: 30)
            label.textAlignment = .center
            return label
        }()
        
        let view = UIView()
        
        view.addSubview(imgView)
        imgView.snp.makeConstraints { make in
            make.size.equalToSuperview().multipliedBy(0.9)
        }
        
        view.addSubview(playlistTitle)
        playlistTitle.snp.makeConstraints { make in
            make.size.centerX.centerY.equalToSuperview()
        }
        
        addSubview(view)
        view.frame = contentView.bounds
    }
}

