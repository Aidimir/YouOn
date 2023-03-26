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
import RxRelay
import RxCocoa

class BindableTableViewController<T: AnimatableSectionModelType>: UIViewController {
        
    var items: RxSwift.Observable<[T]>
    
    var onItemMoved: ((ItemMovedEvent) -> Void)?
    
    var onItemRemoved: ((IndexPath) -> Void)?
    
    let tableView = UITableView()
    
    var classesToRegister: [String: AnyClass]
    
    var dataSource: RxTableViewSectionedAnimatedDataSource<T>
        
    let disposeBag = DisposeBag()
    
    init(items: RxSwift.Observable<[T]>,
         onItemMoved: ((ItemMovedEvent) -> Void)? = nil,
         onItemRemoved: ((IndexPath) -> Void)? = nil,
         dataSource: RxTableViewSectionedAnimatedDataSource<T>,
         classesToRegister: [String: AnyClass] ) {
        self.items = items
        self.dataSource = dataSource
        self.classesToRegister = classesToRegister
        self.onItemMoved = onItemMoved
        self.onItemRemoved = onItemRemoved
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
        
        tableView.rx.itemDeleted
            .asDriver()
            .drive(onNext: onItemRemoved)
            .disposed(by: disposeBag)
        
        tableView.rx.itemMoved
            .asDriver()
            .drive(onNext: onItemMoved)
            .disposed(by: disposeBag)
        
        items.bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.size.equalToSuperview()
        }
    }
    
}
