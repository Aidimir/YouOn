//
//  CurrentStorageViewController.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 12.06.2023.
//

import Foundation
import UIKit
import SnapKit

class CurrentStorageViewController: DraggableViewController {
    
    private var tableView: UITableView
    
    private lazy var dragView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray
        view.layer.cornerRadius = 5
        return view
    }()
    
    private enum Constants {
        static let verticalPadding = 30
        static let smallVerticalPadding = 10
        static let horizontalPadding = 20
    }
    
    init(tableView: UITableView) {
        self.tableView = tableView
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkGray
        addSubviews()
    }
    
    private func addSubviews() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height / 12))
        
        let currentStorageLabel = UILabel()
        currentStorageLabel.font = .largeFont
        currentStorageLabel.text = "Current playlist"
        currentStorageLabel.textColor = .white
        currentStorageLabel.textAlignment = .center
        
        headerView.addSubview(dragView)
        dragView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(Constants.smallVerticalPadding)
            make.width.equalToSuperview().dividedBy(10)
            make.height.equalTo(6)
        }
        
        headerView.addSubview(currentStorageLabel)
        currentStorageLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(dragView.snp.bottom).offset(Constants.smallVerticalPadding)
        }
        
        headerView.backgroundColor = .darkGray
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction))
        headerView.addGestureRecognizer(panGesture)
                
        view.addSubview(headerView)
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(Constants.smallVerticalPadding)
            make.left.right.bottom.equalToSuperview()
        }
    }
}
