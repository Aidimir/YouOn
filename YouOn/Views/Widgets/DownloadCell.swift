//
//  DownloadCell.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 30.03.2023.
//

import Foundation
import UIKit
import SnapKit
import RxSwift

class DownloadCell: UITableViewCell {
    private var progressCircleView: ProgressCircleView?
    private var titleLabel: UILabel?
    
    private var disposeBag = DisposeBag()
    
    func setup(model: DownloadModel, progressCircleView: ProgressCircleView, circleRadiusSize: CGFloat) {
        titleLabel = .createScrollableLabel()
        titleLabel?.text = model.title
        
        self.progressCircleView = progressCircleView
        
        addSubview(progressCircleView)
        progressCircleView.snp.makeConstraints({ make in
            make.right.centerY.equalTo(contentView.readableContentGuide)
            make.height.width.equalTo(circleRadiusSize)
        })
        
        model.progress.bind(to: progressCircleView.rx.currentProgress).disposed(by: disposeBag)
        
        addSubview(titleLabel!)
        titleLabel!.snp.makeConstraints { make in
            make.left.top.bottom.equalTo(contentView.readableContentGuide)
            make.right.equalTo(progressCircleView.snp.left)
        }
    }
    
    override func prepareForReuse() {
        progressCircleView?.removeFromSuperview()
        titleLabel?.removeFromSuperview()
        progressCircleView = nil
        titleLabel = nil
        super.prepareForReuse()
    }
}
