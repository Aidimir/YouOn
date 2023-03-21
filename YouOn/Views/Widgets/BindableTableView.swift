//
//  BindableTableView.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 20.03.2023.
//

import Foundation
import RxSwift
import RxDataSources
import SnapKit

class BindableTableViewController<T: SectionModelType>: UIViewController {
    
    var items: RxSwift.Observable<[T]>
    
    let tableView = UITableView()
    
    var classesToRegister: [String: AnyClass]
    
    var dataSource: RxTableViewSectionedReloadDataSource<T>
        
    private let disposeBag = DisposeBag()
    
    init(items: RxSwift.Observable<[T]>,
         dataSource: RxTableViewSectionedReloadDataSource<T>,
         classesToRegister: [String: AnyClass]) {
        self.items = items
        self.dataSource = dataSource
        self.classesToRegister = classesToRegister
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for (key, value) in classesToRegister {
            tableView.register(value, forCellReuseIdentifier: key)
        }
        
        items.bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.equalTo(view.readableContentGuide.snp.left)
            make.right.equalTo(view.readableContentGuide.snp.right)
            make.top.equalTo(view.readableContentGuide.snp.top)
            make.bottom.equalTo(view.readableContentGuide.snp.bottom)
        }
    }
    
}
