//
//  List.swift
//  StreamView
//
//  Created by Yura Granchenko on 4/11/17.
//  Copyright © 2017 Yura Granchenko. All rights reserved.
//

import Foundation

public class List<T: Equatable> {
    
    public var sorter: (_ lhs: T, _ rhs: T) -> Bool = { _,_  in return true }
    
    convenience public init(sorter: @escaping (_ lhs: T, _ rhs: T) -> Bool) {
        self.init()
        self.sorter = sorter
    }
    
    public var entries = [T]()
    
    internal func _add(entry: T) -> Bool {
        if !entries.contains(entry) {
            entries.append(entry)
            return true
        } else {
            return false
        }
    }
    
    public func add(entry: T) {
        if _add(entry: entry) {
            sort()
        }
    }
    
    public func addEntries<S: Sequence>(entries: S) where S.Iterator.Element == T {
        let count = self.entries.count
        for entry in entries {
            let _ = _add(entry: entry)
        }
        if count != self.entries.count {
            sort()
        }
    }
    
    public func sort(entry: T) {
        let _ = _add(entry: entry)
        sort()
    }
    
    public func sort() {
        entries = entries.sorted(by: sorter)
    }
    
    public func remove(entry: T) {
        if let index = entries.index(of: entry) {
            entries.remove(at: index)
        }
    }
    
    public subscript(index: Int) -> T? {
        return (index >= 0 && index < count) ? entries[index] : nil
    }
}

public protocol BaseOrderedContainer {
    associatedtype ElementType
    var count: Int { get }
    subscript (safe index: Int) -> ElementType? { get }
}

extension Array: BaseOrderedContainer {}

extension List: BaseOrderedContainer {
    public var count: Int { return entries.count }
    public subscript (safe index: Int) -> T? {
        return entries[safe: index]
    }
}

extension Array {
    public subscript (safe index: Int) -> Element? {
        return (index >= 0 && index < count) ? self[index] : nil
    }
}

extension Array where Element: Equatable {
    
    public mutating func remove(_ element: Element) {
        if let index = index(of: element) {
            self.remove(at: index)
        }
    }
}

extension Collection {
    
    public func all(_ enumerator: (Iterator.Element) -> Void) {
        for element in self {
            enumerator(element)
        }
    }
    
    public subscript (includeElement: (Iterator.Element) -> Bool) -> Iterator.Element? {
        for element in self where includeElement(element) == true {
            return element
        }
        return nil
    }
}

extension Dictionary {
    
    public func get<T>(_ key: Key) -> T? {
        return self[key] as? T
    }
}
