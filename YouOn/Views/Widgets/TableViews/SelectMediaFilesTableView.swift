//
//  SelectMediaFilesTableView.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 26.03.2023.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class SelectMediaFilesTableView: UIViewController, UITableViewDelegate, UITableViewDataSource {
        
    var source: [MediaFileUIProtocol]
    
    private lazy var tableView = UITableView()
    
    private lazy var saveButton = UIButton()
    
    private let saveAction: (([IndexPath]) -> Void)?

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
        cell.setup(file: source[indexPath.row], foregroundColor: .black, backgroundColor: .black)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return source.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.frame.size.height / 10
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath) as? MediaFileCell
        selectedCell?.isSelected = true
        selectedCell?.didSelect()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath) as? MediaFileCell
        selectedCell?.isSelected = false
        selectedCell?.didDeselect()
    }

    override func viewDidLoad() {
        view.backgroundColor = .black
        
        saveButton.addTarget(self, action: #selector(onSaveTap), for: .touchUpInside)
        saveButton.setTitle("Add", for: .normal)
        saveButton.tintColor = .green
        
        tableView.register(MediaFileCell.self, forCellReuseIdentifier: "MediaFileCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .black
        tableView.allowsMultipleSelection = true
        tableView.separatorColor = .clear
        
        view.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.right.equalTo(view.readableContentGuide.snp.right)
            make.width.equalTo(100)
            make.height.equalTo(50)
        }
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(saveButton.snp.bottom).offset(10)
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
