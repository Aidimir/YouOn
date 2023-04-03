//
//  MediaFileCell.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 20.03.2023.
//

import Foundation
import UIKit
import SnapKit
import MarqueeLabel
import Kingfisher

protocol MoreActionsTappedDelegate: AnyObject {
    func onMoreActionsTapped(cell: UITableViewCell)
}

class MediaFileCell: UITableViewCell {
        
    weak var delegate: MoreActionsTappedDelegate?
    
    private var nameLabel: MarqueeLabel!
    
    private var authorLabel: MarqueeLabel!
    
    private var durationLabel: UILabel!
    
    private var imgView: UIImageView!
        
    public func setup(file: MediaFileUIProtocol,
                      backgroundColor: UIColor,
                      imageCornerRadius: CGFloat = 0,
                      fadeLength: CGFloat = 20,
                      animationDuration: CGFloat = 6,
                      supportsMoreActions: Bool = false) {
        
        nameLabel = MarqueeLabel(frame: .zero, duration: animationDuration, fadeLength: 0)
        nameLabel.animationDelay = 2
        nameLabel.fadeLength = fadeLength
        nameLabel.text = file.title
        nameLabel.textColor = .white
        nameLabel.font = .boldSystemFont(ofSize: 20)
        
        authorLabel = MarqueeLabel(frame: .zero, duration: animationDuration, fadeLength: 0)
        authorLabel.animationDelay = 2
        authorLabel.fadeLength = fadeLength
        authorLabel.text = file.author
        authorLabel.textColor = .gray
        authorLabel.font = .boldSystemFont(ofSize: 15)
        
        durationLabel = UILabel()
        let duration = file.duration.stringTime
        durationLabel.text = duration
        durationLabel.textAlignment = .right
        durationLabel.textColor = .gray
        
        imgView = UIImageView(image: nil)
        imgView.kf.setImage(with: file.imageURL)
        imgView.contentMode = .scaleToFill
        imgView.layer.cornerRadius = imageCornerRadius
        imgView.clipsToBounds = true
        
        
        addSubview(imgView)
        imgView.snp.makeConstraints { make in
            make.centerY.left.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.95)
            make.width.equalToSuperview().dividedBy(5)
        }
        
        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.height.equalToSuperview().dividedBy(2.5)
            make.left.equalTo(imgView.snp.right).offset(contentView.bounds.width / 15)
            make.top.equalTo(imgView)
            make.width.equalToSuperview().multipliedBy(0.6)
        }
        
        addSubview(durationLabel)
        durationLabel.snp.makeConstraints { make in
            make.right.equalTo(nameLabel)
            make.bottom.equalTo(imgView)
        }
        
        addSubview(authorLabel)
        authorLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.right.equalTo(durationLabel.snp.left).offset(-10)
            make.bottom.equalTo(imgView)
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
            
            addSubview(formattingIcon)
            formattingIcon.snp.makeConstraints { make in
                make.right.centerY.equalToSuperview()
                make.width.height.equalTo(50)
            }
        }
        
        contentView.backgroundColor = backgroundColor
    }
    
    @objc private func onTap() {
        delegate?.onMoreActionsTapped(cell: self)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            UIView.animate(withDuration: 0.2, animations: { [weak self] in
                self?.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            }, completion: { [weak self] finished in
                UIView.animate(withDuration: 0.2) {
                    self?.transform = .identity
                }
            })
        }
    }
    
    public func didSelect() {
        tintColor = .green
        isSelected = true
        accessoryType = .checkmark
    }
    
    public func didDeselect() {
        isSelected = false
        accessoryType = .none
    }
    
    override func prepareForReuse() {
        isSelected = false
        super.prepareForReuse()
        nameLabel.removeFromSuperview()
        authorLabel.removeFromSuperview()
        durationLabel.removeFromSuperview()
        imgView.removeFromSuperview()
        nameLabel = nil
        authorLabel = nil
        durationLabel = nil
        imgView = nil
    }
}

