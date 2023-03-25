//
//  LibraryViewController.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 20.03.2023.
//

import Foundation
import UIKit
import RxDataSources
import SnapKit
import RxSwift
import RxCocoa

protocol LibraryViewProtocol {
    var viewModel: (any LibraryViewModelProtocol)? { get set }
}

class LibraryViewController: UIViewController, LibraryViewProtocol, AllPlaylistsTableViewDelegate {
    
    var viewModel: (any LibraryViewModelProtocol)?
    
    private var playlistsTableView: UIViewController?
        
    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Library"
        tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: "books.vertical")?.withTintColor(.black), selectedImage: UIImage(systemName: "books.vertical.fill")?.withTintColor(.black))
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backgroundColor = UIColor.darkGray
        
        let dataSource = RxTableViewSectionedAnimatedDataSource<PlaylistSectionModel> { _, tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath) as! PlaylistCell
            cell.setup(uiModel: item, foregroundColor: .clear,
                       backgroundColor: backgroundColor, cornerRadius: 10)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            return cell
        } canEditRowAtIndexPath: { [weak self] source, indexPath in
            return self?.viewModel?.uiModels.value[indexPath.row].isDeletable ?? false
        } canMoveRowAtIndexPath: { [weak self] source, indexPath in
            return self?.viewModel?.uiModels.value[indexPath.row].isDeletable ?? false
        }
        
        if let viewModel = viewModel {
            
            let cellsToRegister = ["PlaylistCell": PlaylistCell.self]
            
            let itemImage = UIImage(systemName: "plus")
            let barItem = UIBarButtonItem(image: itemImage, style: .plain, target: self, action: #selector(addPlaylist))
            barItem.tintColor = .black
            navigationItem.rightBarButtonItem = barItem
            
            let allPlTableView = AllPlaylistsTableView(heightForRow: view.frame.size.height / 6,
                                                       backgroundColor: .clear,
                                                       tableViewColor: .clear,
                                                       items:
                                                        viewModel.uiModels
                                                        .asObservable()
                                                        .map({ [AnimatableSectionModel(model: "",
                                                                                       items: $0.map({ PlaylistUIModel(model: $0)}))] }),
                                                       itemsAsRelay: viewModel.uiModels,
                                                       onItemMoved: onItemMoved(_:),
                                                       onItemRemoved: onItemRemoved(_:),
                                                       classesToRegister: cellsToRegister,
                                                       dataSource: dataSource)
            allPlTableView.delegate = self
            
            playlistsTableView = allPlTableView
            
            view.backgroundColor = backgroundColor
            
            addChild(playlistsTableView!)
            view.addSubview(playlistsTableView!.view)
            playlistsTableView?.view.snp.makeConstraints { make in
                make.left.right.top.bottom.equalTo(view.readableContentGuide)
            }
            playlistsTableView?.didMove(toParent: self)
        }
    }
    
    func didTapOnPlaylist(indexPath: IndexPath) {
        viewModel?.didTapOnPlaylist(indexPath: indexPath)
    }
    
    @objc private func addPlaylist() {
        showInputDialog(title: "Add playlist", subtitle: nil, actionTitle: "Add", cancelTitle: "Cancel", inputPlaceholder: nil, inputKeyboardType: .default, cancelHandler: nil) { [weak self] text in
            if text != nil {
                if !text!.isEmpty {
                    self?.viewModel?.addPlaylist(text!)
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func onItemMoved(_ event: ItemMovedEvent) -> Void {
        guard viewModel != nil, let item = viewModel?.uiModels.value[event.sourceIndex.row] else { return }
        viewModel!.uiModels.replaceElement(at: event.sourceIndex.row, insertTo: event.destinationIndex.row, with: item)
        viewModel?.saveAllPlaylists()
    }
    
    private func onItemRemoved(_ indexPath: IndexPath) -> Void {
        guard viewModel != nil else { return }
        if let canDelete = viewModel?.uiModels.value[indexPath.row].isDeletable, canDelete == true {
            viewModel?.removePlaylist(indexPath: indexPath)
        }
    }
}
