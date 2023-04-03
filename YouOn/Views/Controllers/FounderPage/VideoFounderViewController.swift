//
//  VideoFounderViewController.swift
//  YouOn
//
//  Created by Айдимир Магомедов on 20.03.2023.
//

import Foundation
import SnapKit
import UIKit
import RxDataSources
import RxSwift
import RxCocoa

protocol VideoFounderViewProtocol {
    var viewModel: VideoFounderViewModelProtocol { get set }
}

class VideoFounderViewController: UIViewController,
                                  UITextFieldDelegate,
                                  VideoFounderViewProtocol {
    
    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .white
        return spinner
    }()
    
    private var searchField: UITextField!
    
    private var button: UIButton!
    
    private var downloadsTableView: UIViewController?
    
    private lazy var progressView: UIView = UIView()
    
    var viewModel: VideoFounderViewModelProtocol
    
    private var progressLabel: UILabel!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkGray
        
        let classesToRegister = ["DownloadCell": DownloadCell.self]
        
        let dataSource = RxTableViewSectionedAnimatedDataSource<DownloadsSectionModel> { [weak self] _, tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "DownloadCell", for: indexPath) as! DownloadCell
            cell.setup(model: item, circleRadiusSize: cell.frame.height / 2) { [weak self] in
                self?.viewModel.cancelDownloading(downloadModel: item)
            }
            cell.backgroundColor = .black
            cell.layer.cornerRadius = 15
            cell.clipsToBounds = true
            cell.selectionStyle = .none
            return cell
        } canEditRowAtIndexPath: { source, indexPath in
            return false
        }
        
        searchField = {
            let textField = UITextField()
            textField.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            textField.layer.cornerRadius = 10
            textField.layer.masksToBounds = true
            textField.delegate = self
            textField.returnKeyType = .done
            textField.adjustsFontSizeToFitWidth = true
            textField.placeholder = "Paste your YouTube video link to download it"
            textField.setLeftPaddingPoints(20)
            textField.setRightPaddingPoints(20)
            return textField
        }()
        
        button = UIButton()
        button.backgroundColor = .black
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        button.setTitle("Download", for: .normal)
        button.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        
        let allDownloadsTableView = BindableTableViewController(items:
                                                                    viewModel.itemsOnDownloading.asObservable().map({ [AnimatableSectionModel(model: "", items: $0 )] }),
                                                                heightForRow: view.frame.size.height / 10,
                                                                tableViewColor: .clear,
                                                                dataSource: dataSource,
                                                                classesToRegister: classesToRegister)
        
        downloadsTableView = allDownloadsTableView
        downloadsTableView?.view.layer.cornerRadius = 20
        
        view.addSubview(searchField)
        searchField.snp.makeConstraints({ make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.9)
            make.height.equalToSuperview().multipliedBy(0.06)
        })
        
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.top.equalTo(searchField.snp.bottom).offset(view.frame.height * 0.01)
            make.width.equalToSuperview().dividedBy(2.5)
            make.height.equalToSuperview().dividedBy(13)
            make.centerX.equalToSuperview()
        }
        
        button.addSubview(spinner)
        spinner.snp.makeConstraints { make in
            make.size.equalTo(button)
        }
        
        addChild(downloadsTableView!)
        view.addSubview(downloadsTableView!.view)
        downloadsTableView!.view.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.centerX.equalTo(view.readableContentGuide)
            make.width.equalTo(view.readableContentGuide.snp.width)
            make.bottom.equalTo(searchField.snp.top).offset(-50)
        }
        downloadsTableView!.didMove(toParent: self)
        
        setBindings()
    }
    
    @objc private func onTap() {
        viewModel.onSearchTap()
    }
    
    private func setBindings() {
        viewModel.waitingToResponse.bind { [weak self] val in
            if val {
                self?.spinner.startAnimating()
                self?.button.alpha = 0.5
            } else {
                self?.spinner.stopAnimating()
                self?.button.alpha = 1
            }
        }.disposed(by: disposeBag)
        
        searchField.rx.text.orEmpty.bind(to: viewModel.searchFieldString)
            .disposed(by: disposeBag)
        
        viewModel.isValid.subscribe(onNext: { [weak self] val in
            self?.button.isEnabled = val
            self?.button.alpha = val ? 1 : 0.5
        }).disposed(by: disposeBag)
    }
    
    init(viewModel: VideoFounderViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = "Finder"
        
        self.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: "magnifyingglass.circle"), selectedImage: UIImage(systemName: "magnifyingglass.circle.fill"))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension VideoFounderViewController {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
