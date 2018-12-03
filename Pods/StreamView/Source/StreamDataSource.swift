//
//  StreamDataSource.swift
//  StreamView
//
//  Created by Yura Granchenko on 4/11/17.
//  Copyright © 2017 Yura Granchenko. All rights reserved.
//

import Foundation
import UIKit

open class StreamDataSource<T: BaseOrderedContainer>: NSObject, StreamViewDataSource, UIScrollViewDelegate where T.ElementType: Any {
    
    public var streamView: StreamView
    
    public var sectionHeaderMetrics = [StreamMetricsProtocol]()
    
    public var metrics = [StreamMetricsProtocol]()
    
    public var sectionFooterMetrics = [StreamMetricsProtocol]()
    
    deinit {
        if (streamView.delegate as? StreamDataSource) == self {
            streamView.delegate = nil
        }
    }
    
    open var items: T? {
        didSet {
            didSetItems()
        }
    }
    
    open func didSetItems() {
        reload()
    }
    
    open func reload() {
        if streamView.dataSource as? StreamDataSource == self {
            streamView.reload()
        }
    }
    
    @discardableResult open func addSectionHeaderMetrics<T: StreamMetricsProtocol>(metrics: T) -> T {
        sectionHeaderMetrics.append(metrics)
        return metrics
    }
    
    @discardableResult open func addMetrics<T: StreamMetricsProtocol>(metrics: T) -> T {
        self.metrics.append(metrics)
        return metrics
    }
    
    @discardableResult open func addSectionFooterMetrics<T: StreamMetricsProtocol>(metrics: T) -> T {
        sectionFooterMetrics.append(metrics)
        return metrics
    }
    
    required public init(streamView: StreamView) {
        self.streamView = streamView
        super.init()
        self.streamView = streamView
        streamView.delegate = self
        streamView.dataSource = self
      
    }
    
    open var numberOfItems: Int?
    
    open var didLayoutItemBlock: ((StreamItem) -> Void)?
    
    private func entryForItem(item: StreamItem) -> Any? {
        return items?[safe: item.position.index]
    }
    
    open func numberOfItemsIn(section: Int) -> Int {
        return numberOfItems ?? items?.count ?? 0
    }
    
    open func metricsAt(position: StreamPosition) -> [StreamMetricsProtocol] {
        return metrics
    }
    
    open func didLayoutItem(item: StreamItem) {
        didLayoutItemBlock?(item)
    }
    
    open func entryBlockForItem(item: StreamItem) -> ((StreamItem) -> Any?)? {
        return { [weak self] item -> Any? in
            return self?.entryForItem(item: item)
        }
    }
    
    open func didChangeContentSize(oldContentSize: CGSize) {}
    
    open func didLayout() {}
    
    open func headerMetricsIn(section: Int) -> [StreamMetricsProtocol] {
        return sectionHeaderMetrics
    }
    
    open func footerMetricsIn(section: Int) -> [StreamMetricsProtocol] {
        return sectionFooterMetrics
    }
    
    open func numberOfSections() -> Int {
        return 1
    }
    
    open var didEndDecelerating: (() -> ())?
    open var willBeginDragging: (() -> ())?
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        willBeginDragging?()
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            didEndDecelerating?()
        }
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didEndDecelerating?()
    }
}
