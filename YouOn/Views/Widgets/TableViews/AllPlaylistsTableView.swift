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
import RxRelay
import RxCocoa

protocol AllPlaylistsTableViewDelegate {
    func didTapOnPlaylist(indexPath: IndexPath)
}

typealias PlaylistSectionModel = AnimatableSectionModel<String, PlaylistUIModel>

class AllPlaylistsTableView: BindableTableViewController<PlaylistSectionModel>, UITableViewDelegate, UITableViewDragDelegate {
    
    private var heightForRow: CGFloat
    
    private var backgroundColor: UIColor
    
    private var itemsAsRelay: BehaviorRelay<[PlaylistUIProtocol]>?
    
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
         itemsAsRelay: BehaviorRelay<[PlaylistUIProtocol]>?,
         onItemMoved: ((ItemMovedEvent) -> Void)? = nil,
         onItemRemoved: ((IndexPath) -> Void)? = nil,
         classesToRegister: [String: AnyClass],
         dataSource: RxTableViewSectionedAnimatedDataSource<PlaylistSectionModel>) {
        self.heightForRow = heightForRow
        self.backgroundColor = backgroundColor
        self.itemsAsRelay = itemsAsRelay
        
        super.init(items: items,
                   onItemMoved: onItemMoved,
                   onItemRemoved: onItemRemoved,
                   dataSource: dataSource,
                   classesToRegister: classesToRegister)
        
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
        tableView.dragDelegate = self
    }
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = itemsAsRelay?.value[indexPath.row]
        return [dragItem]
    }
}
