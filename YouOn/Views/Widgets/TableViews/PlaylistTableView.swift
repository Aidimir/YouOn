//
//  PlaylistTableView.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 22.03.2023.
//

import Foundation
import UIKit
import RxSwift
import Differentiator
import RxDataSources
import RxRelay
import RxCocoa

protocol PlaylistTableViewProtocol {
    func onMediaFileTapped(indexPath: IndexPath)
}

typealias MediaFilesSectionModel = AnimatableSectionModel<String, MediaFileUIModel>

class PlaylistTableView: BindableTableViewController<MediaFilesSectionModel>, UITableViewDelegate, UITableViewDragDelegate {
    
    private var heightForRow: CGFloat
    
    private var backgroundColor: UIColor
    
    private var itemsAsRelay: BehaviorRelay<[MediaFileUIProtocol]>?
    
    var delegate: PlaylistTableViewProtocol?
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return heightForRow
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.onMediaFileTapped(indexPath: indexPath)
    }
    
    init(heightForRow: CGFloat,
         backgroundColor: UIColor,
         tableViewColor: UIColor,
         items: Observable<[MediaFilesSectionModel]>,
         itemsAsRelay: BehaviorRelay<[MediaFileUIProtocol]>?,
         onItemMoved: ((ItemMovedEvent) -> Void)? = nil,
         onItemRemoved: ((IndexPath) -> Void)? = nil,
         classesToRegister: [String: AnyClass],
         dataSource: RxTableViewSectionedAnimatedDataSource<MediaFilesSectionModel>) {
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
