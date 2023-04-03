//
//  PlaylistTableViewHeader.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 03.04.2023.
//

import Foundation
import UIKit
import SnapKit

class PlaylistHeaderView: UIView {
    
    var imgView: UIImageView = {
       let imgView = UIImageView()
        imgView.tintColor = .gray
        imgView.contentMode = .scaleAspectFit
        imgView.layer.cornerRadius = 10
        imgView.clipsToBounds = true
        return imgView
    }()
    
    var titleLabel: UILabel = {
       let label = UILabel()
        label.textColor = .white
        label.font = .titleFont
        label.sizeToFit()
        return label
    }()
    
    private enum Constants {
        static let horizontalSpadding = 20
        static let verticalPadding = 20
    }
    
    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        print(title)
        addViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addViews() {
        addSubview(imgView)
        imgView.snp.makeConstraints { make in
            make.bottom.width.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(imgView).offset(Constants.verticalPadding)
            make.left.equalTo(imgView).offset(Constants.horizontalSpadding)
            make.right.equalTo(imgView).inset(Constants.horizontalSpadding)
        }
        titleLabel.backgroundColor = .blue
        
        imgView.backgroundColor = .red
    }
}
