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

class BindableTableViewController<T: AnimatableSectionModelType>: UIViewController, UITableViewDelegate, UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = tableView.cellForRow(at: indexPath)
        return [dragItem]
    }
    
    var items: RxSwift.Observable<[T]>?
    
    var onItemSelected: ((IndexPath) -> Void)?
    
    var onItemMoved: ((ItemMovedEvent) -> Void)?
    
    var onItemRemoved: ((IndexPath) -> Void)?
    
    var tableView: UITableView
    
    var classesToRegister: [String: AnyClass]
    
    weak var dataSource: RxTableViewSectionedAnimatedDataSource<T>?
    
    var heightForRow: CGFloat
    
    var supportsDragging: Bool
    
    private let disposeBag = DisposeBag()
    
    init(items: RxSwift.Observable<[T]>?,
         heightForRow: CGFloat,
         tableViewColor: UIColor = .clear,
         onItemSelected: ((IndexPath) -> Void)? = nil,
         onItemMoved: ((ItemMovedEvent) -> Void)? = nil,
         onItemRemoved: ((IndexPath) -> Void)? = nil,
         dataSource: RxTableViewSectionedAnimatedDataSource<T>,
         classesToRegister: [String: AnyClass],
         supportsDragging: Bool = false,
         style: UITableView.Style? = .plain) {
        self.heightForRow = heightForRow
        self.items = items
        self.dataSource = dataSource
        self.classesToRegister = classesToRegister
        self.onItemSelected = onItemSelected
        self.onItemMoved = onItemMoved
        self.onItemRemoved = onItemRemoved
        self.supportsDragging = supportsDragging
        tableView = UITableView(frame: .zero, style: style ?? .plain)
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
        
        items?.bind(to: tableView.rx.items(dataSource: dataSource!))
            .disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .asDriver()
            .drive(onNext: onItemSelected)
            .disposed(by: disposeBag)
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.size.equalToSuperview()
        }
        
        tableView.separatorColor = .clear
        
        if supportsDragging {
            tableView.dragDelegate = self
            tableView.rx.itemMoved
                .asDriver()
                .drive(onNext: onItemMoved)
                .disposed(by: disposeBag)
        }
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
    }
}
