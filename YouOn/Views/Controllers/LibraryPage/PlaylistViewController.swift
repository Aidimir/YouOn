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

protocol PlaylistViewProtocol {
    var viewModel: (any PlaylistViewModelProtocol)? { get set }
}

class PlaylistViewController: UIViewController, PlaylistViewProtocol, PlaylistViewModelDelegate, MoreActionsTappedDelegate {
    
    func onMoreActionsTapped(cell: UITableViewCell) {
        if let indexPath = tableViewController?.tableView.indexPath(for: cell), let model = viewModel?.uiModels.value[indexPath.row], let viewModel = viewModel {
            let headerView = MediaFileAsHeaderView(model: model)
            actionsController = DisplayActionsTableView(source: viewModel.fetchActionModels(indexPath: indexPath), headerView: headerView)
        }
        
        present(actionsController!, animated: true)
    }
    
    
    var viewModel: (any PlaylistViewModelProtocol)?
    
    var tableViewController: PlaylistTableView?
    
    private var actionsController: DisplayActionsTableView?
    
    func onMediaFileTapped(indexPath: IndexPath) {
        viewModel?.playSong(indexPath: indexPath)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backgroundColor = UIColor.darkGray
        
        let classesToRegister = ["MediaFileCell": MediaFileCell.self]
        
        if let viewModel = viewModel {
            
            self.viewModel?.delegate = self
            
            let dataSource = RxTableViewSectionedAnimatedDataSource<MediaFilesSectionModel> { _, tableView, indexPath, item in
                let cell = tableView.dequeueReusableCell(withIdentifier: "MediaFileCell", for: indexPath) as! MediaFileCell
                
                cell.setup(file: item, foregroundColor: backgroundColor, backgroundColor: backgroundColor, imageCornerRadius: 10, supportsMoreActions: true)
                cell.delegate = self
                cell.backgroundColor = .clear
                cell.selectionStyle = .none
                return cell
            } titleForHeaderInSection: { source, sectionIndex in
                return source[sectionIndex].model
            } canEditRowAtIndexPath: { source, indexPath in
                return true
            } canMoveRowAtIndexPath: { source, IndexPath in
                return true
            }
            
            let playlistTableView = PlaylistTableView(heightForRow: view.frame.size.height / 10,
                                                      backgroundColor: .clear,
                                                      tableViewColor: .clear,
                                                      items: viewModel.uiModels
                .asObservable()
                .map({ [AnimatableSectionModel(model: "",
                                               items: $0.map({ MediaFileUIModel(model: $0) }))] }),
                                                      itemsAsRelay: viewModel.uiModels,
                                                      onItemMoved: onItemMoved(_:),
                                                      onItemRemoved: onItemRemoved(_:),
                                                      onItemSelected: onItemSelected(_:),
                                                      classesToRegister: classesToRegister,
                                                      dataSource: dataSource)
            
            tableViewController = playlistTableView
            
            view.backgroundColor = backgroundColor
            
            addChild(tableViewController!)
            
            view.addSubview(tableViewController!.view)
            tableViewController!.view.snp.makeConstraints { make in
                make.left.equalTo(view.readableContentGuide.snp.left)
                make.right.equalToSuperview()
                make.top.bottom.equalTo(view)
            }
            
            tableViewController?.didMove(toParent: self)
        }
    }
    
    private func onItemMoved(_ event: ItemMovedEvent) -> Void {
        guard let viewModel = viewModel else { return }
        let item = viewModel.uiModels.value[event.sourceIndex.row]
        viewModel.uiModels.replaceElement(at: event.sourceIndex.row, insertTo: event.destinationIndex.row, with: item)
        viewModel.saveStorage()
    }
    
    private func onItemRemoved(_ indexPath: IndexPath) -> Void {
        guard let viewModel = viewModel else { return }
        viewModel.removeFromPlaylist(indexPath: indexPath)
    }
    
    private func onItemSelected(_ indexPath: IndexPath) -> Void {
        guard let viewModel = viewModel else { return }
        viewModel.playSong(indexPath: indexPath)
    }
    
    @objc private func addFiles() {
        viewModel?.moveToAddFilesController()
    }
    
    func barItemIf(_ isAddable: Bool) {
        if isAddable {
            let itemImage = UIImage(systemName: "plus")
            let barItem = UIBarButtonItem(image: itemImage, style: .plain, target: self, action: #selector(addFiles))
            barItem.tintColor = .white
            navigationItem.rightBarButtonItem = barItem
        }
        title = viewModel?.title
    }
}
