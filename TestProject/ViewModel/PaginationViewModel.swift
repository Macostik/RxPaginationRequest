//
//  PaginationViewModel.swift
//  TestProject
//
//  Created by Yura on 11/25/18.
//  Copyright © 2018 Yura. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import RxAlamofire
import SwiftyJSON

class PaginationViewModel {
    let indicatorViewAnimating: Driver<Bool>
    let elements: Driver<[Feed]>
    let loadError: Driver<Error>
    
    private let loadAction: Action<Int, [Feed]>
    private let disposeBag = DisposeBag()
    
    init(refresher: PublishSubject<Refresher>,
         viewWillAppear: Driver<Void>,
         scrollViewDidReachBottom: Driver<Void>) {
        var articleCount = 0
        let defaultArticlesCount = 20
        loadAction = Action { page in
            APIManager.articles(["tags": "story", "page": page])
                .json().map({ json in
                    let data = json["hits"].arrayValue
                    let result = data.map({ Feed.init(with: $0) })
                    articleCount += result.count
                    return result
                })
        }

        indicatorViewAnimating = loadAction.executing.asDriver(onErrorJustReturn: false)
        elements = loadAction.elements.asDriver(onErrorDriveWith: .empty())
            .scan([]) { $0.count < defaultArticlesCount ? $1 : $0 + $1 }
            .startWith([])

        loadError = loadAction.errors.asDriver(onErrorDriveWith: .empty())
            .flatMap { error -> Driver<Error> in
                switch error {
                case .underlyingError(let error):
                    return Driver.just(error)
                case .notEnabled:
                    return Driver.empty()
                }
        }
        
        viewWillAppear.asObservable()
            .map { _ in 1 }
            .subscribe(loadAction.inputs)
            .disposed(by: disposeBag)

        refresher
            .withLatestFrom(loadAction.elements)
            .flatMap { _ in Observable.of(articleCount/defaultArticlesCount + 1) }
            .subscribe(loadAction.inputs)
            .disposed(by: disposeBag)
    }
}
