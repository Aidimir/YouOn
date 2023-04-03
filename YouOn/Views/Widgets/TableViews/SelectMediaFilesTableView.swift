//
//  SelectMediaFilesTableView.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 26.03.2023.
//

import Foundation
import UIKit

class SelectMediaFilesTableView: UIViewController, UITableViewDelegate, UITableViewDataSource {
        
    var source: [MediaFileUIProtocol]
    
    private var selected: [IndexPath] = []
    
    private lazy var tableView = UITableView()
    
    private lazy var saveButton = UIButton()
    
    private lazy var titleLabel = UILabel()
    
    private lazy var dragView: UIView = {
       let view = UIView()
        view.backgroundColor = .gray
        return view
    }()
    
    private let saveAction: (([IndexPath]) -> Void)?
    
    private enum Constants {
        static let buttonWidth = 100
        static let buttonHeight = 50
        static let horizontalPadding = 30
        static let verticalPadding = 15
        static let roundedCornerRadius = 10
    }

    init(source: [MediaFileUIProtocol], saveAction: (([IndexPath]) -> Void)?) {
        self.saveAction = saveAction
        self.source = source
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MediaFileCell", for: indexPath) as! MediaFileCell
        cell.setup(file: source[indexPath.row], backgroundColor: .clear, imageCornerRadius: 10)

        if selected.contains(where: { $0 == indexPath }) {
            cell.didSelect()
        } else {
            cell.didDeselect()
        }
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return source.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.frame.size.height / 8
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath) as? MediaFileCell
        selected.append(indexPath)
        selectedCell?.didSelect()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath) as? MediaFileCell
        selected = selected.filter({ $0 != indexPath })
        selectedCell?.didDeselect()
    }

    override func viewDidLoad() {
        view.backgroundColor = .black
        
        saveButton.addTarget(self, action: #selector(onSaveTap), for: .touchUpInside)
        saveButton.setTitle("Add", for: .normal)
        saveButton.setTitleColor(.black, for: .normal)
        saveButton.backgroundColor = .white
        saveButton.layer.cornerRadius = CGFloat(Constants.roundedCornerRadius)
        saveButton.clipsToBounds = true
        
        tableView.register(MediaFileCell.self, forCellReuseIdentifier: "MediaFileCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.allowsMultipleSelection = true
        tableView.separatorColor = .clear
        
        titleLabel.text = "Add media to playlist"
        titleLabel.textColor = .white
        titleLabel.font = .titleFont
        titleLabel.adjustsFontSizeToFitWidth = true
        
        view.addSubview(dragView)
        dragView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(Constants.verticalPadding)
            make.width.equalToSuperview().dividedBy(10)
            make.height.equalTo(6)
        }
        
        view.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(dragView).offset(Constants.verticalPadding)
            make.right.equalTo(view).inset(Constants.horizontalPadding)
            make.width.equalTo(Constants.buttonWidth)
            make.height.equalTo(Constants.buttonHeight)
        }
        
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.right.equalTo(saveButton.snp.left).inset(Constants.horizontalPadding)
            make.left.equalTo(view.readableContentGuide)
            make.top.bottom.equalTo(saveButton)
        }
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(saveButton.snp.bottom).offset(Constants.verticalPadding)
            make.bottom.equalToSuperview()
            make.left.right.equalTo(view.readableContentGuide)
        }
        
        view.bringSubviewToFront(saveButton)
    }
    
    @objc private func onSaveTap() {
        if let items = tableView.indexPathsForSelectedRows {
            saveAction?(items)
        }
        dismiss(animated: true)
    }
}
