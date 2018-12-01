//
//  FeedCell.swift
//  TestProject
//
//  Created by Yura on 11/25/18.
//  Copyright © 2018 Yura. All rights reserved.
//

import Foundation
import UIKit

class FeedCell: UITableViewCell, BindableCell {
    func bind(_ feed: Feed) {
        textLabel?.text = feed.title
        detailTextLabel?.text = feed.created_at
    }
}
