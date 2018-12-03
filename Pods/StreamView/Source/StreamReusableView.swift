//
//  StreamReusableView.swift
//  StreamView
//
//  Created by Yura Granchenko on 4/11/17.
//  Copyright © 2017 Yura Granchenko. All rights reserved.
//

import Foundation
import UIKit

open class StreamReusableView: UIView, UIGestureRecognizerDelegate {
    
    open func setEntry(entry: Any?) {}
    open func getEntry() -> Any? { return nil }
    
    open var metrics: StreamMetricsProtocol?
    open var item: StreamItem?
    open var selected: Bool = false
    open let selectTapGestureRecognizer = UITapGestureRecognizer()
    
    open func layoutWithMetrics(metrics: StreamMetricsProtocol) {}
    
    open func didLoad() {
        selectTapGestureRecognizer.addTarget(self, action: #selector(self.selectAction))
        selectTapGestureRecognizer.delegate = self
        self.addGestureRecognizer(selectTapGestureRecognizer)
    }
    
    @IBAction func selectAction() {
        metrics?.select(view: self)
    }
    
    open func didDequeue() {}
    
    open func willEnqueue() {}
    
    open func resetup() {}
    
    // MARK: - UIGestureRecognizerDelegate
    
    override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer != selectTapGestureRecognizer || metrics?.selectable ?? false
    }
}

open class EntryStreamReusableView<T: Any>: StreamReusableView {
    
    public init() {
        super.init(frame: CGRect.zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func setEntry(entry: Any?) {
        self.entry = entry as? T
    }
    
    override open func getEntry() -> Any? {
        return entry
    }
    
    open var entry: T? {
        didSet {
            resetup()
        }
    }
    
    open func setup(entry: T) {}
    
    open func setupEmpty() {}
    
    override open func resetup() {
        if let entry = entry {
            setup(entry: entry)
        } else {
            setupEmpty()
        }
    }
}
