//
//  StreamItem.swift
//  VXTrade
//  StreamView
//
//  Created by Yura Granchenko on 4/11/17.
//  Copyright © 2017 Yura Granchenko. All rights reserved.
//

import Foundation
import UIKit

public final class StreamItem {
    
    public var frame = CGRect.zero
    public var visible = false
    public let position: StreamPosition
    public let metrics: StreamMetricsProtocol
    public var entryBlock: ((StreamItem) -> Any?)?
    
    public init(metrics: StreamMetricsProtocol, position: StreamPosition) {
        self.metrics = metrics
        self.position = position 
        hidden = metrics.hidden
        size = metrics.size
        insets = metrics.insets
        ratio = metrics.ratio
    }
    
    public lazy var entry: Any? = self.entryBlock?(self)
    
    public weak var view: StreamReusableView? {
        willSet { newValue?.selected = selected }
    }
    
    public var selected: Bool = false {
        willSet { view?.selected = newValue }
    }
    
    public weak var previous: StreamItem?
    public weak var next: StreamItem?
    
    public  var column: Int = 0
    public var hidden: Bool = false
    public var size: CGFloat = 0
    public var insets: CGRect = CGRect.zero
    public var ratio: CGFloat = 0
}

public func ==(lhs: StreamPosition, rhs: StreamPosition) -> Bool {
    return lhs.section == rhs.section && lhs.index == rhs.index
}

public struct StreamPosition: Equatable {
    public let section: Int
    public let index: Int
    static let zero = StreamPosition(section: 0, index: 0)
}

