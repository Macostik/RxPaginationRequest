//
//  StreamView.swift
//  StreamView
//
//  Created by Yura Granchenko on 4/11/17.
//  Copyright © 2017 Yura Granchenko. All rights reserved.
//

import Foundation
import UIKit

public enum ScrollDirection {
    case Unknown, Up, Down
}

public enum PositionScroll {
    case top, middle, bottom
}

var StreamViewCommonLocksChanged: String = "StreamViewCommonLocksChanged"

public protocol StreamViewDataSource: class {
    func numberOfSections() -> Int
    func numberOfItemsIn(section: Int) -> Int
    func metricsAt(position: StreamPosition) -> [StreamMetricsProtocol]
    func didLayoutItem(item: StreamItem)
    func entryBlockForItem(item: StreamItem) -> ((StreamItem) -> Any?)?
    func didChangeContentSize(oldContentSize: CGSize)
    func didLayout()
    func headerMetricsIn(section: Int) -> [StreamMetricsProtocol]
    func footerMetricsIn(section: Int) -> [StreamMetricsProtocol]
}

extension StreamViewDataSource {
    func numberOfSections() -> Int { return 1 }
    func didLayoutItem(item: StreamItem) { }
    func entryBlockForItem(item: StreamItem) -> ((StreamItem) -> Any?)? { return nil }
    func didChangeContentSize(oldContentSize: CGSize) { }
    func didLayout() { }
    func headerMetricsIn(section: Int) -> [StreamMetricsProtocol] { return [] }
    func footerMetricsIn(section: Int) -> [StreamMetricsProtocol] { return [] }
}

public class StreamViewLayer: CALayer {
    
    public var didChangeBounds: (() -> Void)?
    
    override public var bounds: CGRect {
        didSet {
            didChangeBounds?()
        }
    }
}

public class StreamView: UIScrollView {
    
    override public class var layerClass: AnyClass {
        return StreamViewLayer.self
    }
    
    public var layout: StreamLayout = StreamLayout()
    
    private var reloadAfterUnlock = false
    
    public var locked = false
    
    public var forceShowPlaceholder = false
    
    static public var locked = false
    
    private var items = [StreamItem]()
    
    public weak var dataSource: StreamViewDataSource?
    
    public weak var placeholderView: PlaceholderView? {
        willSet {
            newValue?.isHidden = isHidden
        }
    }
    
    override public var isHidden: Bool {
        didSet {
            placeholderView?.isHidden = isHidden
        }
    }
    
    public var placeholderViewBlock: (() -> PlaceholderView)?
    
    override public var contentInset: UIEdgeInsets {
        didSet {
            if oldValue != contentInset && items.count == 1 && layout.finalized {
                reload()
            }
        }
    }
    
    deinit {
        delegate = nil
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: StreamViewCommonLocksChanged), object: nil)
    }
    
    private func setup() {
        (layer as! StreamViewLayer).didChangeBounds = { [unowned self] in
            self.didChangeBounds()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(StreamView.locksChanged), name: NSNotification.Name(rawValue: StreamViewCommonLocksChanged), object: nil)
    }
    
    public var scrollDirectionChanged: ((_ isUp: Bool) -> Void)?
    public var directionHelper: ((_ isUp: Bool) -> Void)?
    
    public var trackScrollDirection = false
    
    public var direction: ScrollDirection = .Unknown {
        didSet {
            if direction != oldValue {
                scrollDirectionChanged?(direction == .Up)
            }
        }
    }
    
    public func didChangeBounds() {
        if trackScrollDirection && isTracking && (contentSize.height > height || direction == .Up) {
            direction = panGestureRecognizer.translation(in: self).y > 0 ? .Down : .Up
            directionHelper?(direction == .Up)
        }
        if layout.finalized {
            updateVisibility()
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func clear() {
        placeholderView?.removeFromSuperview()
        for item in items {
            if let view = item.view {
                view.isHidden = true
                item.metrics.enqueueView(view: view)
            }
        }
        items.removeAll()
    }
    
    static public func lock() {
        locked = true
    }
    
    static public func unlock() {
        if locked {
            locked = false
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: StreamViewCommonLocksChanged), object: nil)
        }
    }
    
    @objc public func locksChanged() {
        if !locked && !StreamView.locked && reloadAfterUnlock {
            reloadAfterUnlock = false
            reload()
        }
    }
    
    public func lock() {
        locked = true
    }
    
    public func unlock() {
        if locked {
            locked = false
            locksChanged()
        }
    }
    
    public func reload() {
        
        if locked || StreamView.locked {
            reloadAfterUnlock = true
            return
        }
        
        clear()
        
        layout.prepareLayout(streamView: self)
        
        addItems()
        
        if let item = items.last {
            changeContentSize(newContentSize: layout.contentSize(item: item, streamView: self))
        } else {
            if layout.horizontal {
                changeContentSize(newContentSize: CGSize.init(width: 0, height: height))
            } else {
                changeContentSize(newContentSize: CGSize.init(width: width, height: 0))
            }
        }
        
        layout.finalizeLayout()
        
        _layoutSize = layoutSize(rect: layer.bounds)
        
        dataSource?.didLayout()
        
        updateVisibility()
    }
    
    private func changeContentSize(newContentSize: CGSize) {
        let oldContentSize = contentSize
        if newContentSize != oldContentSize {
            contentSize = newContentSize
            dataSource?.didChangeContentSize(oldContentSize: oldContentSize)
        }
    }
    
    private func addItems() {
        
        guard let dataSource = dataSource else { return }
        let layout = self.layout
        
        for section in 0..<dataSource.numberOfSections() {
            
            let position = StreamPosition(section: section, index: 0)
            for header in dataSource.headerMetricsIn(section: section) {
                _ = addItem(metrics: header, position: position)
            }
            
            for i in 0..<dataSource.numberOfItemsIn(section: section) {
                let position = StreamPosition(section: section, index: i)
                for metrics in dataSource.metricsAt(position: position) {
                    if let item = addItem(dataSource: dataSource, metrics: metrics, position: position) {
                        dataSource.didLayoutItem(item: item)
                    }
                }
            }
            
            for footer in dataSource.footerMetricsIn(section: section) {
                _ = addItem(metrics: footer, position: position)
            }
            
            layout.prepareForNextSection()
        }
        if items.isEmpty || forceShowPlaceholder, let placeholder = placeholderViewBlock {
            let placeholderView = placeholder()
            self.placeholderView = placeholderView
        }
    }
    
    private func addItem(dataSource: StreamViewDataSource? = nil, metrics: StreamMetricsProtocol, position: StreamPosition) -> StreamItem? {
        let item = StreamItem(metrics: metrics, position: position)
        item.entryBlock = dataSource?.entryBlockForItem(item: item)
        metrics.modifyItem?(item)
        guard !item.hidden else { return nil }
        if let currentItem = items.last {
            item.previous = currentItem
            currentItem.next = item
        }
        layout.layoutItem(item: item, streamView: self)
        items.append(item)
        return item
    }
    
    private func updateVisibility() {
        updateVisibility(withRect: layer.bounds)
    }
    
    private var _layoutSize: CGFloat = 0
    
    private func layoutSize(rect: CGRect) -> CGFloat {
        return layout.horizontal ? rect.height : rect.width
    }
    
    private func reloadIfNeeded(rect: CGRect) -> Bool {
        let size = layoutSize(rect: rect)
        if abs(_layoutSize - size) >= 1 {
            reload()
            return true
        } else {
            return false
        }
    }
    
    private func updateVisibility(withRect rect: CGRect) {
        guard !reloadIfNeeded(rect: rect) else { return }
        for item in items {
            let visible = item.frame.intersects(rect)
            if item.visible != visible {
                item.visible = visible
                if visible {
                    let view = item.metrics.dequeueViewWithItem(item: item)
                    if view.superview != self {
                        insertSubview(view, at: 0)
                    }
                    view.isHidden = false
                } else if let view = item.view {
                    item.metrics.enqueueView(view: view)
                    view.isHidden = true
                    item.view = nil
                }
            }
        }
    }
    
    // MARK: - User Actions
    
    public func visibleItems() -> [StreamItem] {
        return itemsPassingTest { $0.visible }
    }
    
    public func selectedItems() -> [StreamItem] {
        return itemsPassingTest { $0.selected && $0.entry != nil }
    }
    
    public var selectedItem: StreamItem? {
        return itemPassingTest { $0.selected }
    }
    
    public func itemPassingTest(test: (StreamItem) -> Bool) -> StreamItem? {
        for item in items where test(item) {
            return item
        }
        return nil
    }
    
    @discardableResult public func itemsPassingTest(test: (StreamItem) -> Bool) -> [StreamItem] {
        return items.filter(test)
    }
    
    public func selectSingleItem(item: StreamItem) {
        _ = items.map({ $0.selected = $0.position.index == item.position.index && !item.selected  })
    }
    
    @discardableResult public func scrollToItemPassingTest( test: (StreamItem) -> Bool, positionScroll: PositionScroll = .middle, animated: Bool) -> StreamItem? {
        let item = itemPassingTest(test: test)
        scrollToItem(item: item, positionScroll: positionScroll, animated: animated)
        return item
    }
    
    public func scrollToItem(item: StreamItem?, positionScroll: PositionScroll = .middle, animated: Bool) {
        guard let item = item else { return }
        let minOffset = minimumContentOffset
        let maxOffset = maximumContentOffset
        if layout.horizontal {
            var offset: CGFloat = 0
            switch positionScroll {
            case .top:
                offset = item.frame.origin.x - contentInset.right
            case .middle:
                offset = (item.frame.origin.x - contentInset.right) - fittingContentWidth / 2 + item.frame.size.width / 2
            case .bottom:
                offset = (item.frame.origin.x - contentInset.right) - fittingContentWidth + item.frame.size.width
            }
            if offset < minOffset.x {
                setContentOffset(minOffset, animated: animated)
            } else if offset > maxOffset.x {
                setContentOffset(maxOffset, animated: animated)
            } else {
                setContentOffset(CGPoint.init(x: offset, y: 0), animated: animated)
            }
        } else {
            var offset: CGFloat = 0
            switch positionScroll {
            case .top:
                offset = item.frame.origin.y - contentInset.top
            case .middle:
                offset = (item.frame.origin.y - contentInset.top) - fittingContentHeight / 2 + item.frame.size.height / 2
            case .bottom:
                offset = (item.frame.origin.y - contentInset.top) - fittingContentHeight + item.frame.size.height
            }
            if offset < minOffset.y {
                setContentOffset(minOffset, animated: animated)
            } else if offset > maxOffset.y {
                setContentOffset(maxOffset, animated: animated)
            } else {
                setContentOffset(CGPoint.init(x: 0, y: offset), animated: animated)
            }
        }
    }
    
    override public func touchesShouldCancel(in view: UIView) -> Bool {
        return true
    }
}
