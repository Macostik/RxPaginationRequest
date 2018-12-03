//
//  ScrollView+Ext.swift
//  StreamView
//
//  Created by Yura Granchenko on 4/11/17.
//  Copyright © 2017 Yura Granchenko. All rights reserved.
//

import Foundation

extension UIScrollView {
    public  func setMinimumContentOffsetAnimated(_ animated: Bool) {
        setContentOffset(minimumContentOffset, animated: animated)
    }
    public func setMaximumContentOffsetAnimated(_ animated: Bool) {
        setContentOffset(maximumContentOffset, animated: animated)
    }
    
    public var minimumContentOffset: CGPoint {
        let insets = contentInset
        return CGPoint(x: -insets.left, y: -insets.top)
    }
    
    public var maximumContentOffset: CGPoint {
        let insets = contentInset
        let width = contentSize.width - (frame.width - insets.right)
        let height = contentSize.height - (frame.height - insets.bottom)
        let x = (width > -insets.left) ? width : -insets.left
        let y = (height > -insets.top) ? height : -insets.top
        return CGPoint(x: round(x), y: round(y))
    }
    
    public func isPossibleContentOffset(_ offset: CGPoint) -> Bool {
        let min = minimumContentOffset
        let max = maximumContentOffset
        return offset.x >= min.x && offset.x <= max.x && offset.y >= min.y && offset.y <= max.y
    }
    
    public func trySetContentOffset(_ offset: CGPoint) {
        if isPossibleContentOffset(offset) {
            contentOffset = offset
        }
    }
    
    public func trySetContentOffset(_ offset: CGPoint, animated: Bool) {
        if isPossibleContentOffset(offset) {
            setContentOffset(offset, animated: animated)
        }
    }
    
    public var scrollable: Bool {
        return (contentSize.width > fittingContentWidth) || (contentSize.height > fittingContentHeight)
    }
    
    public var verticalContentInsets: CGFloat {
        return contentInset.top + contentInset.bottom
    }
    
    public var horizontalContentInsets: CGFloat {
        return contentInset.left + contentInset.right
    }
    
    public var fittingContentSize: CGSize {
        return CGSize(width: fittingContentWidth, height: fittingContentHeight)
    }
    
    public var fittingContentWidth: CGFloat {
        return frame.width - horizontalContentInsets
    }
    
    public var fittingContentHeight: CGFloat {
        return frame.height - verticalContentInsets
    }
    
    public func visibleRectOfRect(_ rect: CGRect) -> CGRect {
        return visibleRectOfRect(rect, offset:contentOffset)
    }
    
    public func visibleRectOfRect(_ rect: CGRect, offset: CGPoint) -> CGRect {
        return CGRect(origin: offset, size: bounds.size).intersection(rect)
    }
    
    public func keepContentOffset(_ block: () -> ()) {
        let height = self.height
        let offset = self.contentOffset.y
        block()
        self.contentOffset.y = smoothstep(self.minimumContentOffset.y, self.maximumContentOffset.y, offset + (height - self.height))
    }
}

