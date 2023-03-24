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
            
            let allPlTableView = AllPlaylistsTableView(heightForRow: view.frame.size.height / 6,
                                                       backgroundColor: .clear,
                                                       tableViewColor: .clear,
                                                       items:
                                                        viewModel.uiModels
                                                        .asObservable()
                                                        .map({ [AnimatableSectionModel(model: "",
                                                                                       items: $0.map({ PlaylistUIModel(model: $0)}))] }),
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
