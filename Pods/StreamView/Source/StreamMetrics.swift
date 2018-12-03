//
//  StreamMetrics.swift
//  StreamView
//
//  Created by Yura Granchenko on 4/11/17.
//  Copyright © 2017 Yura Granchenko. All rights reserved.
//

import Foundation
import UIKit

public protocol StreamMetricsProtocol: class {
    func enqueueView(view: StreamReusableView)
    func dequeueViewWithItem(item: StreamItem) -> StreamReusableView
    func loadView() -> StreamReusableView
    var hidden: Bool { get set }
    var size: CGFloat { get set }
    var insets: CGRect { get set }
    var ratio: CGFloat { get set }
    var selectable: Bool { get }
    var modifyItem: ((StreamItem) -> Void)? { get }
    func select(view: StreamReusableView)
    var disableMenu: Bool { get }
    var isSeparator: Bool { get set }
}

public class StreamMetrics<T: StreamReusableView>: StreamMetricsProtocol {
    
   public init(layoutBlock: ((T) -> Void)? = nil, size: CGFloat = 0) {
        self.layoutBlock = layoutBlock
        self.size = size
    }
    
   public func change( initializer: (StreamMetrics) -> Void) -> StreamMetrics {
        initializer(self)
        return self
    }
    
    public var layoutBlock: ((T) -> Void)?
    
    public var modifyItem: ((StreamItem) -> Void)?
    
    public var hidden: Bool = false
    public var size: CGFloat = 0
    public var insets: CGRect = CGRect.zero
    public var ratio: CGFloat = 0
    
    public var isSeparator = false
    
    public var selectable = true
    
    public var selection: ((T) -> Void)?
    
    public var prepareAppearing: ((StreamItem, T) -> Void)?
    
    public var finalizeAppearing: ((StreamItem, T) -> Void)?
    
    public var reusableViews: Set<T> = Set()
    
    public var disableMenu = false
    
    public func loadView() -> StreamReusableView {
        let view = T()
        layoutBlock?(view)
        view.metrics = self
        view.didLoad()
        view.layoutWithMetrics(metrics: self)
        return view
    }
    
    public func findView(item: StreamItem) -> T? {
        for view in reusableViews where view.item?.entry as AnyObject === item.entry as AnyObject {
            return view
        }
        return reusableViews.first
    }
    
    public func dequeueView(item: StreamItem) -> T {
        if let view = findView(item: item) {
            reusableViews.remove(view)
            view.didDequeue()
            return view
        }
        return loadView() as! T
    }
    
    public func dequeueViewWithItem(item: StreamItem) -> StreamReusableView {
        let view = dequeueView(item: item)
        view.item = item
        UIView.performWithoutAnimation { view.frame = item.frame }
        item.view = view
        prepareAppearing?(item, view)
        view.setEntry(entry: item.entry)
        finalizeAppearing?(item, view)
        return view
    }
    
    public func enqueueView(view: StreamReusableView) {
        if let view = view as? T {
            view.willEnqueue()
            reusableViews.insert(view)
        }
    }
    
    public func select(view: StreamReusableView) {
        if let view = view as? T {
            selection?(view)
        }
    }
}
