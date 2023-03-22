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
        
        let backgroundColor = UIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1)
        
        let classesToRegister = ["MediaFileCell": MediaFileCell.self]
        
        if let viewModel = viewModel {
            
            let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, MediaFileUIProtocol>> { _, tableView, indexPath, item in
                let cell = tableView.dequeueReusableCell(withIdentifier: "MediaFileCell", for: indexPath) as! MediaFileCell
                cell.setup(file: item, controller: nil, foregroundColor: backgroundColor, backgroundColor: backgroundColor, imageCornerRadius: 30)
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
            
            let playlistTableView = PlaylistTableView(heightForRow: view.frame.size.height / 7,
                                                      backgroundColor: backgroundColor,
                                                      tableViewColor: backgroundColor,
                                                      items: viewModel.uiModels.asObservable(),
                                                      classesToRegister: classesToRegister,
                                                      dataSource: dataSource)
            
            playlistTableView.delegate = self
            
            tableViewController = playlistTableView
            
            addChild(tableViewController!)
            
            tableViewController!.view.frame = view.frame
            
            view.addSubview(tableViewController!.view)
            
            tableViewController?.didMove(toParent: self)
        }
    }
}
