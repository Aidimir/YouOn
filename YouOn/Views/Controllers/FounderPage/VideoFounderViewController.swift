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
    }
    
    private var textField: UITextField!
    
    private var button: UIButton!
    
    private var currentDownload: ProgressCircleView?
    
    private lazy var progressView: UIView = UIView()
    
    var viewModel: VideoFounderViewModelProtocol
    
    private var progressLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkGray

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
        currentDownload = ProgressCircleView(currentProgress: 0, fillColor: UIColor.clear.cgColor, frame: .zero, updateTimeInterval: 0.1)
        currentDownload!.strokeColor = UIColor.green.cgColor
        
        view.addSubview(currentDownload!)
        currentDownload!.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.centerX.equalTo(view.readableContentGuide)
            make.width.equalTo(view.readableContentGuide.snp.width).dividedBy(5)
            make.height.equalTo(view.readableContentGuide.snp.width).dividedBy(5)
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
