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
import StreamView

class SearchFeedsViewController: UIViewController {
    
    @IBOutlet var streamView: StreamView!
    
    private let disposeBag = DisposeBag()
    private var viewModel: PaginationViewModel!
    fileprivate lazy var dataSource: StreamDataSource<[Feed]> = {
        let ds = StreamDataSource<[Feed]>(streamView: self.streamView)
        return ds
    }()
    fileprivate lazy var bottomRefresher = specify(Refresher(scrollView: streamView,
                                                        position: .bottom), { $0.style = .perple })
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        streamView.showsHorizontalScrollIndicator = false
        let metrics = StreamMetrics<FeedCell>()
        metrics.modifyItem = { item in
            let view = metrics.dequeueView(item: item)
            view.titleLabel.text = (item.entry as? Feed)?.title
            view.titleLabel.sizeToFit()
            view.titleLabel.layoutIfNeeded()
            view.descriptionLabel.text = "one"
            view.descriptionLabel.sizeToFit()
            view.descriptionLabel.layoutIfNeeded()
            view.translatesAutoresizingMaskIntoConstraints = false
//
//            view.setNeedsUpdateConstraints()
//            view.updateConstraintsIfNeeded()
//            view.setNeedsLayout()
//            view.layoutIfNeeded()
//            view.invalidateIntrinsicContentSize()
            let height = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            item.size = height.height
        }
        dataSource.addMetrics(metrics: metrics)
       
        viewModel = PaginationViewModel(refresher: bottomRefresher.startRefreshingObservable,
                                        viewWillAppear: rx.viewWillAppear.asDriver(),
                                        scrollViewDidReachBottom:  streamView.rx.reachedBottom.asDriver())
        
         viewModel.indicatorViewAnimating
            .asObservable()
            .subscribe(onNext: { [weak self] isHide in
                if isHide {
                    self?.bottomRefresher.completable =
                        Completable.create(subscribe: { observer in
                        observer(.completed)
                        return Disposables.create()
                    })
                }
            }).disposed(by: disposeBag)
        viewModel.loadError
            .drive(onNext: { print($0) })
            .disposed(by: disposeBag)
        viewModel.elements
            .asObservable()
            .subscribe(onNext: { [weak self] in
                self?.dataSource.items = $0
            }).disposed(by: disposeBag)
    }
}




