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

class PlaylistViewController: UIViewController, PlaylistTableViewProtocol, PlaylistViewProtocol {
    
    var viewModel: (any PlaylistViewModelProtocol)?
    
    var tableViewController: UIViewController?
    
    func onMediaFileTapped(indexPath: IndexPath) {
        viewModel?.playSong(indexPath: indexPath)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backgroundColor = UIColor.darkGray
        
        let classesToRegister = ["MediaFileCell": MediaFileCell.self]
        
        if let viewModel = viewModel {
            
            let dataSource = RxTableViewSectionedAnimatedDataSource<MediaFilesSectionModel> { _, tableView, indexPath, item in
                let cell = tableView.dequeueReusableCell(withIdentifier: "MediaFileCell", for: indexPath) as! MediaFileCell
                cell.setup(file: item, controller: nil, foregroundColor: backgroundColor, backgroundColor: backgroundColor, imageCornerRadius: 10)
                cell.backgroundColor = .clear
                cell.selectionStyle = .none
                return cell
            } titleForHeaderInSection: { source, sectionIndex in
                return source[sectionIndex].model
            } canEditRowAtIndexPath: { source, indexPath in
                //                return dataSource.sectionModels[indexPath.section].items[indexPath.row]
                return true
            } canMoveRowAtIndexPath: { source, IndexPath in
                return true
            }
            
            //        } titleForFooterInSection: { <#TableViewSectionedDataSource<SectionModelType>#>, <#Int#> in
            //            <#code#>
            //        } canEditRowAtIndexPath: { <#TableViewSectionedDataSource<SectionModelType>#>, <#IndexPath#> in
            //            <#code#>
            //        } sectionIndexTitles: { <#TableViewSectionedDataSource<SectionModelType>#> in
            //            <#code#>
            //        } sectionForSectionIndexTitle: { <#TableViewSectionedDataSource<SectionModelType>#>, title, index in
            //            <#code#>
            //        }
            
            let playlistTableView = PlaylistTableView(heightForRow: view.frame.size.height / 10,
                                                      backgroundColor: .clear,
                                                      tableViewColor: .clear,
                                                      items: viewModel.uiModels
                .asObservable()
                .map({ [AnimatableSectionModel(model: "",
                                               items: $0.map({ MediaFileUIModel(model: $0)}))] }),
                                                      itemsAsRelay: viewModel.uiModels,
                                                      onItemMoved: onItemMoved(_:),
                                                      onItemRemoved: onItemRemoved(_:),
                                                      classesToRegister: classesToRegister,
                                                      dataSource: dataSource)
            
            playlistTableView.delegate = self
            
            tableViewController = playlistTableView
            
            view.backgroundColor = backgroundColor
            
            addChild(tableViewController!)
            
            view.addSubview(tableViewController!.view)
            tableViewController!.view.snp.makeConstraints { make in
                make.left.equalTo(view.readableContentGuide.snp.left)
                make.right.equalToSuperview()
                make.top.bottom.equalTo(view.readableContentGuide)
            }
            
            tableViewController?.didMove(toParent: self)
        }
    }
    
    private func onItemMoved(_ event: ItemMovedEvent) -> Void {
        guard viewModel != nil, let item = viewModel?.uiModels.value[event.sourceIndex.row] else { return }
        viewModel!.uiModels.replaceElement(at: event.sourceIndex.row, insertTo: event.destinationIndex.row, with: item)
        viewModel?.saveStorage()
    }
    
    private func onItemRemoved(_ indexPath: IndexPath) -> Void {
        guard viewModel != nil else { return }
        viewModel?.removeFromPlaylist(indexPath: indexPath)
    }
}
