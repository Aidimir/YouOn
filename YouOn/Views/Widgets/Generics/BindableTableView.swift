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

class BindableTableViewController<T: AnimatableSectionModelType>: UIViewController, UITableViewDelegate {
        
    var items: RxSwift.Observable<[T]>
    
    var onItemSelected: ((IndexPath) -> Void)?
    
    var onItemMoved: ((ItemMovedEvent) -> Void)?
    
    var onItemRemoved: ((IndexPath) -> Void)?
    
    let tableView = UITableView()
    
    var classesToRegister: [String: AnyClass]
    
    var dataSource: RxTableViewSectionedAnimatedDataSource<T>
    
    var heightForRow: CGFloat
        
    let disposeBag = DisposeBag()
    
    init(items: RxSwift.Observable<[T]>,
         heightForRow: CGFloat,
         tableViewColor: UIColor = .clear,
         onItemSelected: ((IndexPath) -> Void)? = nil,
         onItemMoved: ((ItemMovedEvent) -> Void)? = nil,
         onItemRemoved: ((IndexPath) -> Void)? = nil,
         dataSource: RxTableViewSectionedAnimatedDataSource<T>,
         classesToRegister: [String: AnyClass] ) {
        self.heightForRow = heightForRow
        self.items = items
        self.dataSource = dataSource
        self.classesToRegister = classesToRegister
        self.onItemSelected = onItemSelected
        self.onItemMoved = onItemMoved
        self.onItemRemoved = onItemRemoved
        super.init(nibName: nil, bundle: nil)
        tableView.backgroundColor = tableViewColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return heightForRow
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
        
        tableView.rx.itemSelected
            .asDriver()
            .drive(onNext: onItemSelected)
            .disposed(by: disposeBag)
        
        items.bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.size.equalToSuperview()
        }
        
        tableView.separatorColor = .clear
        
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
    }
    
}
