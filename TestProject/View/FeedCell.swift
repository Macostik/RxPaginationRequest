//
//  FeedCell.swift
//  TestProject
//
//  Created by Yura on 11/25/18.
//  Copyright © 2018 Yura. All rights reserved.
//

import Foundation
import UIKit
import StreamView
import SnapKit

public func specify<T>(_ object: T, _ specify: (T) -> Void) -> T {
    specify(object)
    return object
}

extension UIView {
    @discardableResult func add<T: UIView>(_ subview: T, _ layout: (_ make: ConstraintMaker) -> Void) -> T {
        addSubview(subview)
        subview.snp.makeConstraints(layout)
        return subview
    }
    
    class func performAnimated( animated: Bool, animation: () -> Void) {
        if animated {
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationBeginsFromCurrentState(true)
        }
        animation()
        if animated {
            UIView.commitAnimations()
        }
    }
}

final class FeedCell: EntryStreamReusableView<Feed> {
    
    private let containerView = UIView()
    private let titleLabel = specify(UILabel()) {
        $0.numberOfLines = 0
    }
    private let descriptionLabel =  specify(UILabel()) {
        $0.numberOfLines = 0
        $0.setContentHuggingPriority(.defaultHigh, for: .vertical)
    }
    
    override func setup(entry: Feed) {
        titleLabel.text = entry.title
        descriptionLabel.text = entry.created_at
    }
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        add(containerView) {
            $0.edges.equalTo(self)
        }
        
        containerView.add(descriptionLabel) {
            $0.leading.trailing.bottom.equalTo(containerView).inset(10)
        }
        
        containerView.add(titleLabel) {
            $0.top.leading.trailing.equalTo(containerView).inset(10)
            $0.bottom.equalTo(descriptionLabel.snp.top).offset(-10)
        }
    }
}
