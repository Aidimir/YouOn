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
import LNPopupController

protocol LibraryViewProtocol: UIViewController {
    var viewModel: (any LibraryViewModelProtocol)? { get set }
    func onPlaylistRenameTapped(indexPath: IndexPath)
    func onAddPlaylistTapped()
}

class LibraryViewController: UIViewController, LibraryViewProtocol, MoreActionsTappedDelegate {
    
    private var actionsController: DisplayActionsTableView?
    
    func onMoreActionsTapped(cell: UITableViewCell) {
        if let indexPath = playlistsTableView?.tableView.indexPath(for: cell), let model = viewModel?.uiModels.value[indexPath.row], let viewModel = viewModel {
            let headerView = PlaylistAsHeaderView(uiModel: model, backgroundColor: .clear)
            actionsController = DisplayActionsTableView(source: viewModel.fetchActionModels(indexPath: indexPath), headerView: headerView, heightForRow: view.frame.size.height / 10, heightForHeader: view.frame.size.height / 8)
        }
        
        actionsController?.modalPresentationStyle = .custom
        actionsController?.transitioningDelegate = self
        
        present(actionsController!, animated: true)
    }
    
    
    private let disposeBag = DisposeBag()
    
    var viewModel: (any LibraryViewModelProtocol)?
    
    private var playlistsTableView: BindableTableViewController<PlaylistSectionModel>?
    
    private var onItemSelected: (IndexPath) -> () {
        return { [weak self] indexPath in
            self?.viewModel?.didTapOnPlaylist(indexPath: indexPath)
        }
    }
    
    private var onItemRemoved: (IndexPath) -> () {
        return { [weak self] indexPath in
            guard let viewModel = self?.viewModel, !viewModel.uiModels.value[indexPath.row].isDefaultPlaylist else { return }
            viewModel.removePlaylist(indexPath: indexPath)
        }
    }
    
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
            let supportsActions = !item.isDefaultPlaylist
            cell.setup(uiModel: item, foregroundColor: .clear,
                       backgroundColor: backgroundColor, cornerRadius: 10, supportsMoreActions: supportsActions)
            cell.delegate = self
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            return cell
        } canEditRowAtIndexPath: { [weak self] source, indexPath in
            let itemIsDefault = self?.viewModel?.uiModels.value[indexPath.row].isDefaultPlaylist
            return !(itemIsDefault ?? true)
        }
        
        if let viewModel = viewModel {
            
            let cellsToRegister = ["PlaylistCell": PlaylistCell.self]
            
            let itemImage = UIImage(systemName: "plus")
            let barItem = UIBarButtonItem(image: itemImage, style: .plain, target: self, action: #selector(onAddPlaylistTapped))
            barItem.tintColor = .white
            navigationItem.rightBarButtonItem = barItem
            
            let allPlTableView = BindableTableViewController(items: viewModel.uiModels
                .asObservable()
                .map({ [AnimatableSectionModel(model: "",
                                               items: $0.map({ PlaylistUIModel(model: $0)}))] })
                                                             , heightForRow: view.frame.size.height / 6,
                                                             onItemSelected: onItemSelected,
                                                             onItemRemoved: onItemRemoved,
                                                             dataSource: dataSource,
                                                             classesToRegister: cellsToRegister)
            
            playlistsTableView = allPlTableView
            allPlTableView.view.backgroundColor = backgroundColor
            allPlTableView.tableView.backgroundColor = backgroundColor
            
            view.backgroundColor = backgroundColor
            
            addChild(playlistsTableView!)
            view.addSubview(playlistsTableView!.view)
            playlistsTableView?.view.snp.makeConstraints { make in
                make.left.right.top.bottom.equalTo(view)
            }
            playlistsTableView?.didMove(toParent: self)
        }
    }
    
    @objc func onAddPlaylistTapped() {
        showInputDialog(title: "Add playlist", subtitle: nil, actionTitle: "Add", cancelTitle: "Cancel", inputPlaceholder: nil, inputKeyboardType: .default, cancelHandler: nil) { [weak self] text in
            if let text = text, !text.isEmpty {
                self?.viewModel?.addPlaylist(text)
            }
        }
    }
    
    func onPlaylistRenameTapped(indexPath: IndexPath) {
        showInputDialog(title: "Rename playlist", subtitle: nil, actionTitle: "Rename", cancelTitle: "Cancel", inputPlaceholder: nil, inputKeyboardType: .default, cancelHandler: nil) { [weak self] text in
            if let text = text, !text.isEmpty {
                self?.viewModel?.changePlaylistTitle(indexPath: indexPath, title: text)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LibraryViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        PresentationController(presentedViewController: presented, presenting: presenting)
    }
}
