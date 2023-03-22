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
import RxCocoa

class BindableTableViewController<T: SectionModelType>: UIViewController {
//    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
////
//    }
    
    
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
    
    struct State<Item> {
        var items: [Item] = []
    }

    func state<Item>(initialState: State<Item>, itemMoved: Observable<ItemMovedEvent>) -> Observable<State<Item>> {
        itemMoved
            .scan(into: initialState) { (state, itemMoved) in
                state.items.move(from: itemMoved.sourceIndex.row, to: itemMoved.destinationIndex.row)
            }
            .startWith(initialState)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        tableView.rx.itemMoved = state(initialState: items, itemMoved: <#T##Observable<ItemMovedEvent>#>)
        
        for (key, value) in classesToRegister {
            tableView.register(value, forCellReuseIdentifier: key)
        }
        
        items.bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.size.equalToSuperview()
        }
    }
    
}
