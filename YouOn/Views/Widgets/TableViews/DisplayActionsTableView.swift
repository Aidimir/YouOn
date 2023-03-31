//
//  DisplayActionsTableView.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 30.03.2023.
//

import Foundation
import UIKit

class DisplayActionsTableView: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var hasSetPointOrigin = false
    
    var pointOrigin: CGPoint?
        
    var source: [ActionModel]
    
    private lazy var tableView = UITableView()
        
    private var headerView: UIView
    
    private var heightForRow: CGFloat
    
    private var heightForHeader: CGFloat

    init(source: [ActionModel], headerView: UIView, heightForRow: CGFloat, heightForHeader: CGFloat) {
        self.source = source
        self.heightForRow = heightForRow
        self.headerView = headerView
        self.heightForHeader = heightForHeader
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !hasSetPointOrigin {
            hasSetPointOrigin = true
            pointOrigin = self.view.frame.origin
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell", for: indexPath) as! ActionCell
        let image = UIImage(systemName: source[indexPath.row].iconName ?? "")
        cell.setup(title: source[indexPath.row].title, onTap: source[indexPath.row].onTap, icon: image)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        source[indexPath.row].onTap?()
        dismiss(animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return source.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return heightForRow
    }

    override func viewDidLoad() {
        view.backgroundColor = .darkGray
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction))
        view.addGestureRecognizer(panGesture)
        
        let slideIndicator = UIView()
        slideIndicator.roundCorners(.allCorners, radius: 10)
        
        view.addSubview(slideIndicator)
        slideIndicator.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.equalTo(10)
            make.height.equalTo(5)
        }
        
        tableView.bounces = false
        tableView.register(ActionCell.self, forCellReuseIdentifier: "ActionCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .darkGray
        tableView.allowsMultipleSelection = true
        tableView.separatorColor = .clear
        
        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.readableContentGuide).offset(50)
            make.left.right.equalTo(view.readableContentGuide)
            make.height.equalTo(heightForHeader)
        }
                
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(50)
            make.bottom.left.right.equalTo(view.readableContentGuide)
        }
    }
    
    @objc func panGestureRecognizerAction(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        
        guard translation.y >= 0 else { return }
        
        view.frame.origin = CGPoint(x: 0, y: self.pointOrigin!.y + translation.y)
        
        if sender.state == .ended {
            let draggedToDismiss = (translation.y > view.frame.size.height/3.0)
            let dragVelocity = sender.velocity(in: view)
            if (dragVelocity.y >= 1300) || draggedToDismiss {
                self.dismiss(animated: true, completion: nil)
            } else {
                // Set back to original position of the view controller
                UIView.animate(withDuration: 0.3) {
                    self.view.frame.origin = self.pointOrigin ?? CGPoint(x: 0, y: 400)
                }
            }
        }
    }
}

