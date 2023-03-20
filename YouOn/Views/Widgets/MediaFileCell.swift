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
    
    public var fadeLength = 20
    
    public var animationDuration = 6
    
    private var controller: UIViewController?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.isUserInteractionEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setup(file: MediaFileUIProtocol, controller: UIViewController? = nil) {
        self.controller = controller
        
        let nameLabel: MarqueeLabel = {
            let label = MarqueeLabel(frame: .zero, duration: CGFloat(animationDuration), fadeLength: 0)
            label.animationDelay = 2
            label.fadeLength = 20
            label.text = file.title
            label.textColor = .white
            label.font = .boldSystemFont(ofSize: 20)
            return label
        }()
        
        let authorLabel: MarqueeLabel = {
            let label = MarqueeLabel(frame: .zero, duration: CGFloat(animationDuration), fadeLength: 0)
            label.animationDelay = 2
            label.fadeLength = CGFloat(fadeLength)
            label.text = file.author
            label.textColor = .gray
            label.font = .boldSystemFont(ofSize: 15)
            return label
        }()
        
        let durationLabel: UILabel = {
            let label = UILabel()
            let duration = file.duration.stringTime
            label.text = duration
            label.textAlignment = .right
            label.textColor = .gray
            return label
        }()
        
        let view: UIView = {
            let view = UIView()
//            view.backgroundColor = UIColor(red: 0.33, green: 0.33, blue: 0.33, alpha: 1)
            view.backgroundColor = .black
            view.isUserInteractionEnabled = true
            
            return view
        }()
        
        let formattingIcon: UIImageView = {
            let image = UIImage(named: "Dots")
            let imgView = UIImageView(image: image)
            imgView.contentMode = .scaleAspectFit
            imgView.tintColor = .white
            return imgView
        }()
        
        let imgView: UIImageView = {
            let imgView = UIImageView(image: nil)
            imgView.kf.setImage(with: file.imageURL)
            imgView.contentMode = .scaleToFill
            imgView.layer.cornerRadius = 15
            imgView.layer.masksToBounds = true
            return imgView
        }()
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap))
        gestureRecognizer.numberOfTapsRequired = 1
        formattingIcon.addGestureRecognizer(gestureRecognizer)
        
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
        
        view.addSubview(authorLabel)
        authorLabel.snp.makeConstraints { make in
            make.centerX.height.width.equalTo(nameLabel)
            make.bottom.equalTo(imgView)
        }
        
        view.addSubview(durationLabel)
        durationLabel.snp.makeConstraints { make in
            make.right.equalTo(nameLabel)
            make.width.equalToSuperview().multipliedBy(0.1)
            make.top.height.equalTo(authorLabel)
        }
        
        addSubview(view)
        view.frame = contentView.bounds
        
        formattingIcon.isUserInteractionEnabled = true
        
        addSubview(formattingIcon)
        formattingIcon.snp.makeConstraints { make in
            make.right.height.top.bottom.equalTo(view)
            make.width.equalTo(view).multipliedBy(0.1)
        }
    }
    
    @objc private func onTap(){
        controller?.modalPresentationStyle = .popover
        controller?.popoverPresentationController?.delegate = self
        controller?.popoverPresentationController?.sourceView = self
        controller?.popoverPresentationController?.sourceRect = CGRect(x: self.bounds.maxX, y: self.bounds.minY, width: 0, height: 0)
        controller?.preferredContentSize = CGSize(width: self.bounds.width/3, height: self.bounds.height)
        getCurrentViewController()?.present(controller ?? UIViewController(), animated: true)
    }
}

extension MediaFileCell: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

