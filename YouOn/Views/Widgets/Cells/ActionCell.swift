//
//  ActionCell.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 30.03.2023.
//

import Foundation
import UIKit

class ActionCell: UITableViewCell {
    private var titleLabel: UILabel?
    private var onTap: (() -> Void)?
    private var imgView: UIImageView?
    
    public func setup(title: String?, onTap: (() -> Void)?, icon: UIImage? = nil, tintColor: UIColor = .white, textColor: UIColor = .white) {
        
        enum Constants {
            static let verticalPadding = 10
            static let horizontalPadding = 10
            static let iconSize = 50
        }

        titleLabel = UILabel()
        titleLabel!.text = title
        titleLabel!.font = .mediumSizeBoldFont
        titleLabel!.textColor = textColor
        titleLabel!.textAlignment = .left
        
        self.onTap = onTap
        imgView = UIImageView()
        imgView?.image = icon
        imgView?.contentMode = .scaleAspectFit
        imgView?.tintColor = tintColor
        
        addSubview(imgView!)
        imgView!.snp.makeConstraints { make in
            make.left.centerY.equalTo(contentView)
            make.width.height.equalTo(contentView.snp.height)
        }
        
        addSubview(titleLabel!)
        titleLabel!.snp.makeConstraints { make in
            make.right.top.bottom.equalTo(contentView)
            make.left.equalTo(imgView!.snp.right).offset(10)
        }
    }
}
