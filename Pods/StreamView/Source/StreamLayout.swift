//
//  StreamLayout.swift
//  StreamView
//
//  Created by Yura Granchenko on 4/11/17.
//  Copyright © 2017 Yura Granchenko. All rights reserved.
//

import Foundation
import UIKit

open class StreamLayout {
    
    public init() {}
    
    open var horizontal: Bool { return false }
    
    open var offset: CGFloat = 0
    
    open var finalized = false
    
    open func prepareLayout(streamView: StreamView) {
        finalized = false
    }
    
    open func contentSize(item: StreamItem, streamView: StreamView) -> CGSize {
        if horizontal {
            return CGSize.init(width: item.frame.maxX, height: streamView.frame.height)
        } else {
            return CGSize.init(width: streamView.frame.width, height: item.frame.maxY)
        }
    }
    
    open func recursivelyLayoutItem(item: StreamItem, streamView: StreamView) {
        var next: StreamItem? = item
        while let item = next {
            item.frame = frameForItem(item: item, streamView: streamView)
            next = item.next
        }
    }
    
    open func layoutItem(item: StreamItem, streamView: StreamView) {
        item.frame = frameForItem(item: item, streamView: streamView)
    }
    
    open func frameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        let size = item.size
        let insets = item.insets
        let offset = item.previous?.frame.maxY ?? self.offset
        return CGRect.init(x: insets.origin.x, y: offset + insets.origin.y, width: streamView.frame.width - insets.origin.x - insets.width, height: size + insets.height)
    }
    
    open func prepareForNextSection() { }
    
    open func finalizeLayout() {
        prepareForNextSection()
        finalized = true
    }
}

public class HorizontalStreamLayout: StreamLayout {
    
    override public var horizontal: Bool { return true }
    
    override public func frameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        let size = item.size
        let insets = item.insets
        let offset = item.previous?.frame.maxX ?? self.offset
        return CGRect.init(x: offset + insets.origin.x, y: insets.origin.y, width: size + insets.width, height: streamView.frame.height - insets.origin.y - insets.height)
    }
}

public class HorizontalViсeVersaStreamLayout: StreamLayout {
    
    override public var horizontal: Bool { return true }
    
    override public func frameForItem(item: StreamItem, streamView: StreamView) -> CGRect {
        let size = item.size
        let insets = item.insets
        let offset = item.previous?.frame.minX ?? UIScreen.main.bounds.width
        return CGRect.init(x: offset - size, y: insets.origin.y, width: size + insets.width, height: streamView.frame.height - insets.origin.y - insets.height)
    }
}
