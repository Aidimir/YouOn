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
    private var onCircleTapped: (() -> Void)?
    
    private var disposeBag = DisposeBag()
    
    func setup(model: DownloadModel, progressCircleView: ProgressCircleView, circleRadiusSize: CGFloat, onCircleTapped: (() -> Void)?) {
        self.onCircleTapped = onCircleTapped
        titleLabel = .createScrollableLabel()
        titleLabel?.text = model.title
        
        self.progressCircleView = progressCircleView
        let gestureRecognizer = UITapGestureRecognizer()
        gestureRecognizer.addTarget(self, action: #selector(onCircleTap))
        self.progressCircleView?.addGestureRecognizer(gestureRecognizer)
        self.progressCircleView?.isUserInteractionEnabled = true
        
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
    
    @objc private func onCircleTap() {
        self.onCircleTapped?()
    }
    
    override func prepareForReuse() {
        progressCircleView?.removeFromSuperview()
        titleLabel?.removeFromSuperview()
        progressCircleView?.gestureRecognizers = nil
        progressCircleView = nil
        titleLabel = nil
        onCircleTapped = nil
        super.prepareForReuse()
    }
}
