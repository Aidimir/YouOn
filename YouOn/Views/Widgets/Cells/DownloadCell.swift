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
    private var gestureRecognizer: UITapGestureRecognizer?
    
    private var disposeBag = DisposeBag()
    
    func setup(model: DownloadModelUIProtocol, circleRadiusSize: CGFloat, onCircleTapped: (() -> Void)?) {
        self.onCircleTapped = onCircleTapped
        titleLabel = .createScrollableLabel()
        titleLabel?.text = model.title
        
        progressCircleView = ProgressCircleView()
        gestureRecognizer = UITapGestureRecognizer()
        gestureRecognizer!.addTarget(self, action: #selector(onCircleTap))
        self.progressCircleView?.addGestureRecognizer(gestureRecognizer!)
        self.progressCircleView?.isUserInteractionEnabled = true
        
        addSubview(self.progressCircleView!)
        self.progressCircleView!.snp.makeConstraints({ make in
            make.right.centerY.equalTo(contentView.readableContentGuide)
            make.height.width.equalTo(circleRadiusSize)
        })
        
        model.progress?.bind(to: self.progressCircleView!.rx.currentProgress).disposed(by: disposeBag)
        
        addSubview(titleLabel!)
        titleLabel!.snp.makeConstraints { make in
            make.left.top.bottom.equalTo(contentView.readableContentGuide)
            make.right.equalTo(self.progressCircleView!.snp.left)
        }
    }
    
    @objc private func onCircleTap() {
        self.onCircleTapped?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        progressCircleView?.removeFromSuperview()
        titleLabel?.removeFromSuperview()
        progressCircleView?.gestureRecognizers = nil
        progressCircleView = nil
        titleLabel = nil
        onCircleTapped = nil
        gestureRecognizer = nil
    }
}
