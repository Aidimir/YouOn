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

class AllPlaylistsTableView: BindableTableViewController<SectionOfPlaylistUI> {
    
    private var heightForRow: CGFloat
    
    private var backgroundColor: UIColor
    
    var delegate: AllPlaylistsTableViewDelegate?
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return heightForRow
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didTapOnPlaylist(indexPath: indexPath)
    }
    
    init(heightForRow: CGFloat, backgroundColor: UIColor,
         items: Observable<[SectionOfPlaylistUI]>,
         dataSource: RxTableViewSectionedReloadDataSource<SectionOfPlaylistUI>) {
        self.heightForRow = heightForRow
        self.backgroundColor = backgroundColor
        super.init(items: items, dataSource: dataSource)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = backgroundColor
    }
}
