//
//  LibraryViewController.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 20.03.2023.
//

import Foundation
import UIKit
import RxDataSources
import RxSwift

protocol LibraryViewProtocol {
    var viewModel: (any LibraryViewModelProtocol)? { get set }
}

class LibraryViewController: UIViewController, LibraryViewProtocol {
    
    var viewModel: (any LibraryViewModelProtocol)?
    
    private var playlistsTableView: UIViewController?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Library"
        tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: "books.vertical")?.withTintColor(.black), selectedImage: UIImage(systemName: "books.vertical.fill")?.withTintColor(.black))

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backgroundColor = UIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1)

        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, PlaylistUIProtocol>> { _, tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath) as! PlaylistCell
            cell.setup(uiModel: item, foregroundColor: .clear,
                       backgroundColor: backgroundColor, cornerRadius: 30)
            return cell
        } titleForHeaderInSection: { source, sectionIndex in
            return source[sectionIndex].model
        }
        //        } titleForFooterInSection: { <#TableViewSectionedDataSource<SectionModelType>#>, <#Int#> in
        //            <#code#>
        //        } canEditRowAtIndexPath: { <#TableViewSectionedDataSource<SectionModelType>#>, <#IndexPath#> in
        //            <#code#>
        //        } canMoveRowAtIndexPath: { <#TableViewSectionedDataSource<SectionModelType>#>, <#IndexPath#> in
        //            <#code#>
        //        } sectionIndexTitles: { <#TableViewSectionedDataSource<SectionModelType>#> in
        //            <#code#>
        //        } sectionForSectionIndexTitle: { <#TableViewSectionedDataSource<SectionModelType>#>, title, index in
        //            <#code#>
        //        }
        
        
        if let viewModel = viewModel {
            
            let cellsToRegister = ["PlaylistCell": PlaylistCell.self]
            
            let color = UIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1)
            
            playlistsTableView = AllPlaylistsTableView(heightForRow: view.frame.size.height / 6,
                                                       backgroundColor: backgroundColor,
                                                       tableViewColor: backgroundColor,
                                                       items: viewModel.uiModels.asObservable(),
                                                       classesToRegister: cellsToRegister,
                                                       dataSource: dataSource)
                        
            addChild(playlistsTableView!)
            
            playlistsTableView!.view.frame = view.frame
            
            view.addSubview(playlistsTableView!.view)
            
            playlistsTableView?.didMove(toParent: self)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
