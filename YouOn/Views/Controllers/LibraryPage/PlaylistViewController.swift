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
import PopMenu

protocol PlaylistViewProtocol {
    var viewModel: (any PlaylistViewModelProtocol)? { get set }
}

class PlaylistViewController: UIViewController, PlaylistViewProtocol, PlaylistViewModelDelegate, MoreActionsTappedDelegate {
    
    var activityVC: UIActivityViewController?
    
    var popMenuViewController: PopMenuViewController?
    
    private var cellToTrack: MediaFileCell?
    
    func onShareButtonTapped(itemsToShare: [Any]) {
        popMenuViewController?.dismiss(animated: true)
        activityVC?.dismiss(animated: true)
        activityVC = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        activityVC!.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.any
        activityVC!.modalPresentationStyle = .automatic
        present(activityVC!, animated: true, completion: nil)
    }
    
    func onMoreActionsTapped(cell: UITableViewCell) {
        let actions = viewModel!.fetchActionModels(indexPath: (tableViewController?.tableView.indexPath(for: cell)!)!).map { element in
            
            var image: UIImage? = nil
            if element.iconName != nil {
                image = UIImage(systemName: element.iconName!)
            }
            
            let action = PopMenuDefaultAction(title: element.title, image: image, color: UIColor.white) { action in element.onTap?() }
            return action
        }
        
        if let cell = cell as? MediaFileCell {
            popMenuViewController = PopMenuViewController(sourceView: cell.moreActionsButton, actions: actions)
            
            popMenuViewController!.appearance.popMenuFont = .mediumSizeBoldFont
            popMenuViewController!.appearance.popMenuBackgroundStyle = .dimmed(color: .black, opacity: 0.6)
            popMenuViewController!.appearance.popMenuItemSeparator = .fill()
            present(popMenuViewController!, animated: true)
        }
    }
    
    
    weak var viewModel: (any PlaylistViewModelProtocol)?
    
    private let disposeBag = DisposeBag()
    
    var tableViewController: BindableTableViewController<MediaFilesSectionModel>?
    
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
        
        addSubviews()
        setBindings()
    }
    
    private func setBindings() {
        viewModel?.currentFile?.asDriver().drive(onNext: { [weak self] model in
            self?.cellToTrack = nil
            if let allCells = (self?.tableViewController?.tableView.visibleCells as? [MediaFileCell])?.filter({ $0.file?.id != model?.id }) {
                allCells.forEach({ $0.playState = .stopped })
            }
        }).disposed(by: disposeBag)
        
        viewModel?.isPlaying?.asDriver(onErrorJustReturn: false).drive(onNext: { [weak self] val in
            if let model = self?.viewModel?.currentFile?.value,
                let cells = (self?.tableViewController?.tableView.visibleCells as? [MediaFileCell])?.filter({ $0.file?.id == model.id }), cells.count > 0 {
                cells.forEach({ $0.playState = .stopped })
                if self?.viewModel?.currentFile?.value?.playlistSpecID != nil {
                    cells.first(where: { $0.file?.playlistSpecID == self?.viewModel?.currentFile?.value?.playlistSpecID })?.playState = val ? .playing : .paused
                } else {
                    cells.first?.playState = val ? .playing : .paused
                }
            }
        }).disposed(by: disposeBag)
    }
    
    private func addSubviews() {
        if let viewModel = viewModel {
            let backgroundColor = UIColor.darkGray
            
            let classesToRegister = ["MediaFileCell": MediaFileCell.self]
            
            asInfoFetched(viewModel.isAddable)
            
            self.viewModel?.delegate = self
            
            let dataSource = RxTableViewSectionedAnimatedDataSource<MediaFilesSectionModel> { [weak self] _, tableView, indexPath, item in
                if let cell = tableView.dequeueReusableCell(withIdentifier: "MediaFileCell", for: indexPath) as? MediaFileCell {
                    let actions = viewModel.fetchActionModels(indexPath: indexPath).map { element in
                        let action = UIAction(handler: { action in element.onTap?() })
                        action.title = element.title ?? ""
                        if element.iconName != nil {
                            action.image = UIImage(systemName: element.iconName!)
                        }
                        return action
                    }
                    
                    cell.setup(file: item,
                               backgroundColor: backgroundColor,
                               imageCornerRadius: 20,
                               supportsMoreActions: true,
                               contextMenuActions: actions)
                    cell.delegate = self
                    cell.backgroundColor = .clear
                    cell.selectionStyle = .none
                    
                    if let disposeBag = self?.disposeBag {
                        if viewModel.isAddable {
                            if let id = viewModel.currentFile?.value?.playlistSpecID {
                                if id.uuidString == item.identity {
                                    viewModel.isPlaying?.take(while: { val in
                                        cell.playState = val ? .playing : .paused
                                        return viewModel.currentFile?.value?.playlistSpecID?.uuidString == item.identity
                                    }).bind(to: cell.rx.isPlaying).disposed(by: disposeBag)
                                } else {
                                    cell.playState = .stopped
                                }
                            } else {
                                if self?.viewModel?.currentFile?.value?.id == item.id {
                                    if self?.cellToTrack == nil || self?.cellToTrack == cell {
                                        viewModel.isPlaying?.take(while: { val in
                                            cell.playState = val ? .playing : .paused
                                            return viewModel.currentFile?.value?.id == item.identity
                                        }).bind(to: cell.rx.isPlaying).disposed(by: disposeBag)
                                        self?.cellToTrack = cell
                                    }
                                }
                            }
                        } else {
                                if viewModel.currentFile?.value?.id == item.id {
                                    viewModel.isPlaying?.take(while: { val in
                                        cell.playState = val ? .playing : .paused
                                        return viewModel.currentFile?.value?.id == item.id
                                    }).bind(to: cell.rx.isPlaying).disposed(by: disposeBag)
                                }
                            }
                        }
                        
                        return cell
                    } else {
                        return UITableViewCell()
                    }
                } canEditRowAtIndexPath: { source, indexPath in
                    return true
                } canMoveRowAtIndexPath: { source, IndexPath in
                    return true
                }
                
                tableViewController = BindableTableViewController(items: viewModel.uiModels
                    .asObservable()
                    .map({ [MediaFilesSectionModel(model: "",
                                                   items: $0.map({ MediaFileUIModel(model: $0) }))]
                    }),
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
