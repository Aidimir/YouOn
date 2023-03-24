//
//  AllPlaylistsTableView.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 20.03.2023.
//

import Foundation
import UIKit
import RxSwift
import RxDataSources

protocol AllPlaylistsTableViewDelegate {
    func didTapOnPlaylist(indexPath: IndexPath)
}

typealias PlaylistSectionModel = AnimatableSectionModel<String, PlaylistUIModel>

class AllPlaylistsTableView: BindableTableViewController<PlaylistSectionModel>, UITableViewDelegate {
    
    private var heightForRow: CGFloat
    
    private var backgroundColor: UIColor
    
    let disposeBag = DisposeBag()
    
    var delegate: AllPlaylistsTableViewDelegate?
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return heightForRow
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didTapOnPlaylist(indexPath: indexPath)
    }
    
    init(heightForRow: CGFloat,
         backgroundColor: UIColor,
         tableViewColor: UIColor,
         items: Observable<[PlaylistSectionModel]>,
         classesToRegister: [String: AnyClass],
         dataSource: RxTableViewSectionedAnimatedDataSource<PlaylistSectionModel>) {
        self.heightForRow = heightForRow
        self.backgroundColor = backgroundColor
        super.init(items: items, dataSource: dataSource, classesToRegister: classesToRegister)
        tableView.backgroundColor = tableViewColor
        view.backgroundColor = backgroundColor
        tableView.separatorColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
    }
}
