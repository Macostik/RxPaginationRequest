//
//  SearchFeedsViewController.swift
//  TestProject
//
//  Created by Yura on 11/25/18.
//  Copyright © 2018 Yura. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SearchFeedsViewController: UIViewController {
    
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    
    private let disposeBag = DisposeBag()
    private var viewModel: PaginationViewModel<Feed>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = PaginationViewModel( viewWillAppear: rx.viewWillAppear.asDriver(),
                                         scrollViewDidReachBottom:  tableView.rx.reachedBottom.asDriver())
        
        viewModel.indicatorViewAnimating.drive(indicatorView.rx.isAnimating).disposed(by: disposeBag)
        viewModel.elements.drive(tableView.rx.items(cellIdentifier: "Cell", cellType: FeedCell.self)).disposed(by: disposeBag)
        viewModel.loadError.drive(onNext: { print($0) }).disposed(by: disposeBag)
        
    }
}
