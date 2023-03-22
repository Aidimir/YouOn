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

protocol PlaylistTableViewProtocol {
    func onMediaFileTapped(indexPath: IndexPath)
}

class PlaylistTableView: BindableTableViewController<SectionModel<String, MediaFileUIProtocol>>, UITableViewDelegate {
    
    private var heightForRow: CGFloat
    
    private var backgroundColor: UIColor
    
    let disposeBag = DisposeBag()
    
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
         items: Observable<[SectionModel<String, MediaFileUIProtocol>]>,
         classesToRegister: [String: AnyClass],
         dataSource: RxTableViewSectionedReloadDataSource<SectionModel<String, MediaFileUIProtocol>>) {
        self.heightForRow = heightForRow
        self.backgroundColor = backgroundColor
        super.init(items: items, dataSource: dataSource, classesToRegister: classesToRegister)
        tableView.backgroundColor = tableViewColor
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
