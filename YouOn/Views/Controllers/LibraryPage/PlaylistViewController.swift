//
//  PlaylistViewController.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 22.03.2023.
//

import Foundation
import UIKit
import RxSwift
import RxDataSources
import SnapKit
import RxCocoa
import ParallaxHeader
import Kingfisher

protocol PlaylistViewProtocol {
    var viewModel: (any PlaylistViewModelProtocol)? { get set }
}

class PlaylistViewController: UIViewController, PlaylistViewProtocol, PlaylistViewModelDelegate, MoreActionsTappedDelegate {
    
    var activityVC: UIActivityViewController?
    
    func onShareButtonTapped(itemsToShare: [Any]) {
        activityVC?.dismiss(animated: true)
        actionsController?.dismiss(animated: true)
        activityVC = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        activityVC!.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.any
        activityVC!.modalPresentationStyle = .automatic
        present(activityVC!, animated: true, completion: nil)
    }
    
    
    func onMoreActionsTapped(cell: UITableViewCell) {
        if let indexPath = tableViewController?.tableView.indexPath(for: cell), let model = viewModel?.uiModels.value[indexPath.row], let viewModel = viewModel {
            let headerView = MediaFileAsHeaderView(model: model)
            actionsController = DisplayActionsTableView(source: viewModel.fetchActionModels(indexPath: indexPath), headerView: headerView, heightForRow: view.frame.size.height / 10, heightForHeader: view.frame.size.height * 0.2)
        }
        
        actionsController?.modalPresentationStyle = .custom
        actionsController?.transitioningDelegate = self
        
        present(actionsController!, animated: true)
    }
    
    
    weak var viewModel: (any PlaylistViewModelProtocol)?
    
    private let disposeBag = DisposeBag()
    
    var tableViewController: BindableTableViewController<MediaFilesSectionModel>?
    
    private var actionsController: DisplayActionsTableView?
    
    private var onItemMoved: (ItemMovedEvent) -> () {
        return { [weak self] (event) in
            guard let viewModel = self?.viewModel else { return }
            let item = viewModel.uiModels.value[event.sourceIndex.row]
            viewModel.uiModels.replaceElement(at: event.sourceIndex.row, insertTo: event.destinationIndex.row, with: item)
            viewModel.saveStorage()
        }
    }
    
    private var onItemRemoved: (IndexPath) -> () {
        return { [weak self] (indexPath) in
            guard let viewModel = self?.viewModel else { return }
            viewModel.removeFromPlaylist(indexPath: indexPath)
        }
    }
    
    private var onItemSelected: (IndexPath) -> () {
        return { [weak self] (indexPath) in
            guard let viewModel = self?.viewModel else { return }
            viewModel.playSong(indexPath: indexPath)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let backgroundColor = UIColor.darkGray
        
        let classesToRegister = ["MediaFileCell": MediaFileCell.self]
        
        if let viewModel = viewModel {
            
            asInfoFetched(viewModel.isAddable)
            
            self.viewModel?.delegate = self
            
            let dataSource = RxTableViewSectionedAnimatedDataSource<MediaFilesSectionModel> { [weak self] _, tableView, indexPath, item in
                if let cell = tableView.dequeueReusableCell(withIdentifier: "MediaFileCell", for: indexPath) as? MediaFileCell {
                    
                    cell.setup(file: item, backgroundColor: backgroundColor, imageCornerRadius: 20, supportsMoreActions: true)
                    cell.delegate = self
                    cell.backgroundColor = .clear
                    cell.selectionStyle = .none
                    return cell
                } else {
                    return UITableViewCell()
                }
            } titleForHeaderInSection: { source, sectionIndex in
                return source[sectionIndex].model
            } canEditRowAtIndexPath: { source, indexPath in
                return true
            } canMoveRowAtIndexPath: { source, IndexPath in
                return true
            }
            
            tableViewController = BindableTableViewController(items: viewModel.uiModels
                .asObservable()
                .map({ [AnimatableSectionModel(model: "",
                                               items: $0.map({ MediaFileUIModel(model: $0) }))] }),
                                                              heightForRow: view.frame.size.height / 10,
                                                              onItemSelected: onItemSelected,
                                                              onItemMoved: onItemMoved,
                                                              onItemRemoved: onItemRemoved,
                                                              dataSource: dataSource,
                                                              classesToRegister: classesToRegister,
                                                              supportsDragging: true)
            
            let placeholder = UIImage(systemName: "music.note.list")
            let headerView = PlaylistHeaderView(title: viewModel.title ?? String())
            
            viewModel.imgURL.asDriver().drive { url in
                if let url = url {
                    headerView.imgView.kf.setImage(with: url, placeholder: nil)
                } else {
                    headerView.imgView.kf.setImage(with: url, placeholder: placeholder)
                }
            }.disposed(by: disposeBag)
            
            tableViewController?.tableView.parallaxHeader.view = headerView
            tableViewController?.tableView.parallaxHeader.height = view.frame.height / 3
            tableViewController?.tableView.parallaxHeader.minimumHeight = 0
            tableViewController?.tableView.parallaxHeader.mode = .topFill
            
            view.backgroundColor = backgroundColor
            
            addChild(tableViewController!)
            
            view.addSubview(tableViewController!.view)
            tableViewController!.view.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.bottom.equalTo(view)
            }
            
            tableViewController?.didMove(toParent: self)
        }
    }
    
    @objc private func addFiles() {
        viewModel?.moveToAddFilesController()
    }
    
    func asInfoFetched(_ isAddable: Bool) {
        if isAddable && navigationItem.rightBarButtonItem == nil {
            let itemImage = UIImage(systemName: "plus")
            let barItem = UIBarButtonItem(image: itemImage, style: .plain, target: self, action: #selector(addFiles))
            barItem.tintColor = .white
            navigationItem.rightBarButtonItem = barItem
        }
        title = viewModel?.title
    }
}

extension PlaylistViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        PresentationController(presentedViewController: presented, presenting: presenting)
    }
}
