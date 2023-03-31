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
    
    var delegate: MoreActionsTappedDelegate?
    
    var imgView = UIImageView()
    
    var playlistTitle = UILabel()
    
    var countLabel = UILabel()
    
    var view = UIView()
    
    private let placeholder = UIImage(systemName: "music.note.list")
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isUserInteractionEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setup(uiModel: PlaylistUIProtocol, foregroundColor: UIColor,
                      backgroundColor: UIColor, cornerRadius: CGFloat = 0, supportsMoreActions: Bool = false) {
        enum Constants {
            static let topPadding = 10
            static let bottomPadding = 10
            static let leftPadding = 10
            static let rightPadding = 10
        }
        
        imgView = UIImageView()
        imgView.kf.setImage(with: uiModel.imageURL, placeholder: placeholder)
        imgView.contentMode = .scaleAspectFill
        imgView.layer.cornerRadius = cornerRadius
        imgView.tintColor = .gray
        imgView.clipsToBounds = true
        
        playlistTitle = UILabel()
        playlistTitle.text = uiModel.title
        playlistTitle.textColor = .white
        playlistTitle.font = .boldSystemFont(ofSize: 30)
        playlistTitle.textAlignment = .center
        
        countLabel = UILabel()
        countLabel.text = uiModel.tracksCountString
        countLabel.textColor = .gray
        countLabel.font = .boldSystemFont(ofSize: 20)
        countLabel.textAlignment = .center

        view = UIView()
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
        
        if supportsMoreActions {
            let image = UIImage(named: "Dots")
            let formattingIcon = UIImageView(image: image)
            formattingIcon.contentMode = .scaleAspectFit
            formattingIcon.tintColor = .white
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap))
            gestureRecognizer.numberOfTapsRequired = 1
            formattingIcon.addGestureRecognizer(gestureRecognizer)
            formattingIcon.isUserInteractionEnabled = true
            
            view.addSubview(formattingIcon)
            formattingIcon.snp.makeConstraints { make in
                make.right.top.bottom.equalTo(view)
                make.width.equalTo(view).multipliedBy(0.1)
            }
        }
        
        addSubview(view)
        view.frame = contentView.bounds
        contentView.backgroundColor = backgroundColor
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imgView.removeFromSuperview()
        playlistTitle.removeFromSuperview()
        countLabel.removeFromSuperview()
        view.removeFromSuperview()
    }
    
    @objc private func onTap() {
        delegate?.onMoreActionsTapped(cell: self)
    }
}