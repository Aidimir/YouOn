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

class MediaFileCell: UITableViewCell {
    
    private var controller: UIViewController?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.isUserInteractionEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setup(file: MediaFileUIProtocol, controller: UIViewController? = nil,
                      foregroundColor: UIColor,
                      backgroundColor: UIColor,
                      imageCornerRadius: CGFloat = 0,
                      fadeLength: CGFloat = 20,
                      animationDuration: CGFloat = 6 ) {
        self.controller = controller
        
        let nameLabel = MarqueeLabel(frame: .zero, duration: animationDuration, fadeLength: 0)
        nameLabel.animationDelay = 2
        nameLabel.fadeLength = fadeLength
        nameLabel.text = file.title
        nameLabel.textColor = .white
        nameLabel.font = .boldSystemFont(ofSize: 20)
        
        let authorLabel = MarqueeLabel(frame: .zero, duration: animationDuration, fadeLength: 0)
        authorLabel.animationDelay = 2
        authorLabel.fadeLength = fadeLength
        authorLabel.text = file.author
        authorLabel.textColor = .gray
        authorLabel.font = .boldSystemFont(ofSize: 15)
        
        let durationLabel = UILabel()
        let duration = file.duration.stringTime
        durationLabel.text = duration
        durationLabel.textAlignment = .right
        durationLabel.textColor = .gray
        
        let view = UIView()
        view.backgroundColor = foregroundColor
        view.isUserInteractionEnabled = true
        
        let imgView = UIImageView(image: nil)
        imgView.kf.setImage(with: file.imageURL)
        imgView.contentMode = .scaleToFill
        imgView.layer.cornerRadius = imageCornerRadius
        imgView.layer.masksToBounds = true
        
        
        view.addSubview(imgView)
        imgView.snp.makeConstraints { make in
            make.centerY.left.equalTo(view)
            make.height.equalTo(view).multipliedBy(0.95)
            make.width.equalTo(view).dividedBy(5)
        }
        
        view.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.height.equalToSuperview().dividedBy(2.5)
            make.left.equalTo(imgView.snp.right).offset(contentView.bounds.width/15)
            make.top.equalTo(imgView)
            make.width.equalToSuperview().multipliedBy(0.6)
        }
        
        view.addSubview(durationLabel)
        durationLabel.snp.makeConstraints { make in
            make.right.equalTo(nameLabel)
            make.bottom.equalTo(imgView)
        }
        
        view.addSubview(authorLabel)
        authorLabel.snp.makeConstraints { make in
            make.left.height.equalTo(nameLabel)
            make.right.equalTo(durationLabel.snp.left).inset(10)
            make.bottom.equalTo(imgView)
        }
        
        addSubview(view)
        view.frame = contentView.bounds
        
        if controller != nil {
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
                make.right.height.top.bottom.equalTo(view)
                make.width.equalTo(view).multipliedBy(0.1)
            }
        }
        
        contentView.backgroundColor = backgroundColor
    }
    
    @objc private func onTap(){
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            UIView.animate(withDuration: 0.2, animations: {
                self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            }, completion: { finished in
                UIView.animate(withDuration: 0.2) {
                    self.transform = .identity
                }
            })
        }
    }
    
    public func didSelect() {
        self.tintColor = .green
        self.accessoryType = .checkmark
    }
    
    public func didDeselect() {
        self.accessoryType = .none
    }
}

extension MediaFileCell: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

