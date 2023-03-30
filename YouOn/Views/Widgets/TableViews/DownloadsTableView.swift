//
//  DownloadsTableView.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 30.03.2023.
//

import Foundation
import UIKit
import RxSwift
import Differentiator
import RxDataSources
import RxRelay
import RxCocoa

protocol DownloadsTableViewDelegate {
    func onDownloadTapped(indexPath: IndexPath)
}

typealias DownloadsSectionModel = AnimatableSectionModel<String, DownloadModel>

class DownloadsTableView: BindableTableViewController<DownloadsSectionModel>, UITableViewDelegate {
    
    private var heightForRow: CGFloat
    
    private var backgroundColor: UIColor
    
    private var itemsAsRelay: BehaviorRelay<[DownloadModel]>?
    
    var delegate: DownloadsTableViewDelegate?
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return heightForRow
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.onDownloadTapped(indexPath: indexPath)
    }
    
    init(heightForRow: CGFloat,
         backgroundColor: UIColor,
         tableViewColor: UIColor,
         items: Observable<[DownloadsSectionModel]>,
         itemsAsRelay: BehaviorRelay<[DownloadModel]>?,
         onItemRemoved: ((IndexPath) -> Void)? = nil,
         classesToRegister: [String: AnyClass],
         dataSource: RxTableViewSectionedAnimatedDataSource<DownloadsSectionModel>) {
        self.heightForRow = heightForRow
        self.backgroundColor = backgroundColor
        self.itemsAsRelay = itemsAsRelay
        
        super.init(items: items,
                   onItemRemoved: onItemRemoved,
                   dataSource: dataSource,
                   classesToRegister: classesToRegister)
        
        tableView.backgroundColor = tableViewColor
        tableView.bounces = false
        view.backgroundColor = backgroundColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
    }
}
