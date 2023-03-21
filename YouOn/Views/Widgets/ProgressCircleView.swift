//
//  ProgressCircleView.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 20.03.2023.
//

import Foundation
import UIKit

class ProgressCircleView: UIView {
    
    private let shapeLayer = CAShapeLayer()
    
    private let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
    
    public var strokeColor: CGColor = .init(gray: 1, alpha: 1)
    
    public var strokeWidth: CGFloat = 10
    
    public var currentProgress: CGFloat
    
    public var lastProgress: CGFloat = 0
    
    public var fillColor: CGColor
    
    public var updateTimeInterval: TimeInterval
    
    var progressLabel: UILabel!
    
    init(currentProgress: CGFloat = 0, fillColor: CGColor,
         frame: CGRect, showProgressLabel: Bool = false, updateTimeInterval: TimeInterval) {
        self.currentProgress = currentProgress
        self.fillColor = fillColor
        self.updateTimeInterval = updateTimeInterval
        super.init(frame: frame)
        if showProgressLabel {
            addView()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addView() {

        progressLabel = {
            let label = UILabel()
            label.textAlignment = .center
            label.font = .boldSystemFont(ofSize: 60)
            label.textColor = .white
            label.adjustsFontSizeToFitWidth = true
            return label
        }()
        
        addSubview(progressLabel)
        progressLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(strokeWidth)
            make.right.equalToSuperview().inset(strokeWidth)
            make.top.equalToSuperview().offset(strokeWidth)
            make.bottom.equalToSuperview().inset(strokeWidth)
        }
    }
    
    @objc public func updateProgress() {
        progressLabel?.text = "\(Int(currentProgress*100))%"
        basicAnimation.fromValue = lastProgress
        
        if (lastProgress != 1) {
            if (currentProgress != lastProgress) {
                basicAnimation.isRemovedOnCompletion = false
                basicAnimation.toValue = currentProgress
                basicAnimation.fillMode = .forwards
                lastProgress = currentProgress
                shapeLayer.add(basicAnimation, forKey: "basicAnimation")
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let circularPath = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                                        radius: frame.size.height / 2,
                                        startAngle: -.pi / 2,
                                        endAngle: 2 * .pi - .pi / 2,
                                        clockwise: true)
        
        shapeLayer.path = circularPath.cgPath
        shapeLayer.strokeColor = UIColor.green.cgColor
        shapeLayer.lineWidth = strokeWidth
        shapeLayer.strokeEnd = 0
        shapeLayer.fillColor = fillColor
        
        layer.addSublayer(shapeLayer)
        
        let timer = Timer.scheduledTimer(timeInterval: updateTimeInterval, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
    }
}
