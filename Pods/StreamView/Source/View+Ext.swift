//
//  View+Ext.swift
//  StreamView
//
//  Created by Yura Granchenko on 4/11/17.
//  Copyright © 2017 Yura Granchenko. All rights reserved.
//

import Foundation
import UIKit

@discardableResult public func specify<T>(object: T, _ specify: (T) -> Void) -> T {
    specify(object)
    return object
}

public func ^(lhs: CGFloat, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs, y: rhs)
}

public func ^(lhs: CGFloat, rhs: CGFloat) -> CGSize {
    return CGSize(width: lhs, height: rhs)
}

public func ^(lhs: CGPoint, rhs: CGSize) -> CGRect {
    return CGRect(origin: lhs, size: rhs)
}

public func smoothstep(_ _min: CGFloat = 0, _ _max: CGFloat = 1, _ value: CGFloat) -> CGFloat {
    return max(_min, min(_max, value))
}

extension UIView {
    
    public  var x: CGFloat {
        set { frame.origin.x = newValue }
        get { return frame.origin.x }
    }
    
    public var y: CGFloat {
        set { frame.origin.y = newValue }
        get { return frame.origin.y }
    }
    
    public var width: CGFloat {
        set { frame.size.width = newValue }
        get { return frame.size.width }
    }
    
    public var height: CGFloat {
        set { frame.size.height = newValue }
        get { return frame.size.height }
    }
    
    public var size: CGSize {
        set { frame.size = newValue }
        get { return frame.size }
    }
    
    public var centerBoundary: CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    @discardableResult public func add<T: UIView>(_ subview: T) -> T {
        addSubview(subview)
        return subview
    }
}
