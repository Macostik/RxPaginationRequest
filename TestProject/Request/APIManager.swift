//
//  APIManager.swift
//  TestProject
//
//  Created by Yura on 11/25/18.
//  Copyright © 2018 Yura. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import RxAlamofire
import SwiftyJSON

enum APIManager: URLRequestConvertible {
    
    case articles([String: Any])
    
    public func asURLRequest() throws -> URLRequest {
        
        let headers: [String: String]? = nil
        
        var method: HTTPMethod {
            switch self {
            case .articles:
                return .get
            }
        }
        
        let parameters: ([String: Any]?) = {
            switch self {
            case .articles(let parameters):
                return parameters
            }
        }()
        
        let url: URL = {
            let query: String?
            switch self {
            case .articles:
                query = "search_by_date"
            }
            
            var URL = Foundation.URL(string: "https://hn.algolia.com/api/v1")!
            if let query = query {
                URL = URL.appendingPathComponent(query)
            }
            return URL
        }()
        
        print("REQUEST for \n\t url - \(url)\n\t method - \(method)\n\t parameters - " +
            "\(parameters ?? [:])")
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        
        if let headers = headers {
            for (headerField, headerValue) in headers {
                urlRequest.setValue(headerValue, forHTTPHeaderField: headerField)
            }
        }
        
        return try URLEncoding.default.encode(urlRequest, with: parameters)
    }
    
    public func json(_ file: Any = #file,
                     function: Any = #function,
                     line: Int = #line) -> RxSwift.Observable<JSON> {
        return RxAlamofire.request(self)
            .observeOn(MainScheduler.instance)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .responseJSON()
            .catchError({ (error) -> Observable<DataResponse<Any>> in
                print("API error for \n\t \(error.localizedDescription)")
                return Observable.error(error)
            })
            .retry(3)
            .share(replay: 1)
            .flatMapLatest { response -> RxSwift.Observable<JSON> in
                let json = JSON(response.result.value ?? NSNull())
                return Observable.just(json)
        }
    }
}
