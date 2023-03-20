//
//  BindableTableView.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 20.03.2023.
//

import Foundation
import RxSwift
import RxDataSources

class BindableTableViewController<T: SectionModelType>: UITableViewController {
    
    var items: RxSwift.Observable<[T]>
    
    var dataSource: RxTableViewSectionedReloadDataSource<T>
    
    private let disposeBag = DisposeBag()
    
    init(items: RxSwift.Observable<[T]>, dataSource: RxTableViewSectionedReloadDataSource<T>) {
        self.items = items
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        items.bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
}
