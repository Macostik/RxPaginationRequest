//
//  Feed.swift
//  TestProject
//
//  Created by Yura on 11/25/18.
//  Copyright © 2018 Yura. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Feed {
    let title: String
    let created_at: String
    
    init(with json: JSON) {
        title      = json["title"].stringValue
        created_at = json["created_at"].stringValue
    }
}
