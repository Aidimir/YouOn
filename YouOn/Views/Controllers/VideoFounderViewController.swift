//
//  VideoFounderViewController.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 20.03.2023.
//

import Foundation
import SnapKit
import UIKit

protocol VideoFounderViewProtocol {
    var viewModel: VideoFounderViewModelProtocol { get set }
}

class VideoFounderViewController: UIViewController,
                                  UITextFieldDelegate,
                                  VideoFounderViewModelDelegate,
                                  VideoFounderViewProtocol {
    
    func downloadProgress(result: Double) {
        currentDownload!.currentProgress = result
        //        currentDownload!.updateProgress()
    }
    
    private var textField: UITextField!
    
    private var button: UIButton!
    
    private var currentDownload: ProgressCircleView?
    
    private lazy var progressView: UIView = UIView()
    
    var viewModel: VideoFounderViewModelProtocol
    
    private var progressLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1)

        textField = {
            let textField = UITextField()
            textField.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            textField.layer.cornerRadius = 10
            textField.layer.masksToBounds = true
            textField.delegate = self
            textField.returnKeyType = .done
            textField.adjustsFontSizeToFitWidth = true
            textField.placeholder = "Paste your YouTube video link to download it"
            textField.setLeftPaddingPoints(20)
            textField.setRightPaddingPoints(20)
            return textField
        }()
        
        button = UIButton()
        button.backgroundColor = .black
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        button.setTitle("Download", for: .normal)
        button.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        
        view.addSubview(textField)
        textField.snp.makeConstraints({ make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.9)
            make.height.equalToSuperview().multipliedBy(0.06)
        })
        
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(view.frame.height * 0.01)
            make.width.equalToSuperview().dividedBy(2.5)
            make.height.equalToSuperview().dividedBy(13)
            make.centerX.equalToSuperview()
        }
        
        viewModel.delegate = self
    }
    
    @objc private func onTap() {
        viewModel.searchFieldString = textField.text!
        viewModel.onSearchTap()
        currentDownload?.removeFromSuperview()
        // frame init is required here, because shapeLayer works only with frame init ( frame size should be the same as autolayout size
        currentDownload = ProgressCircleView(currentProgress: 0, fillColor: UIColor.clear.cgColor, frame: CGRect(x: 0, y: 0, width: button.frame.width*1.5, height: button.frame.width*1.5))
        currentDownload!.strokeColor = UIColor.green.cgColor
        
        view.addSubview(currentDownload!)
        currentDownload!.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(view.frame.height/8)
            make.width.height.equalTo(button.snp.width).multipliedBy(1.5)
            make.centerX.equalToSuperview()
        }
    }
    
    init(viewModel: VideoFounderViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = "Finder"
        
        self.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: "magnifyingglass.circle"), selectedImage: UIImage(systemName: "magnifyingglass.circle.fill"))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension VideoFounderViewController {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
