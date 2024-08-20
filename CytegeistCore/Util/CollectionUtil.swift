//
//  CollectionUtil.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/14/24.
//


public extension RandomAccessCollection {
    func get(index:Index?) -> Element? {
        guard let index, indices.contains(index) else {
            return nil
        }
        return self[index]
    }
}

extension Array where Element: Collection {
    func allSameLength() -> Bool {
        if let firstLength = self.first?.count {
            return self.allSatisfy { $0.count == firstLength }
        }
        return true
    }
}

extension RandomAccessCollection {
    /// Clamps index to the range of the collection.
    /// Will still return nil if the collection is empty
    func get(clampIndex: Index) -> Element? {
        if clampIndex < startIndex {
            return first
        }
        if clampIndex >= endIndex {
            return last
        }
        return self[clampIndex]
    }
}



public struct EnumeratedArray<Value> : BackedRandomAccessCollection {
    public typealias Element = (element: Int, value: Value)
    
    public typealias BackingCollection = Array<Value>
    
    
    public var _indexBacking: Array<Value> { _arr }
    private let _arr: Array<Value>
    
    public init(_ arr:Array<Value>) {
        _arr = arr
    }
    
    public subscript(position: Int) -> Element {
        precondition(position >= startIndex && position < endIndex, "Index out of bounds")
        return (position, _arr[position])
    }
    
//    public subscript(bounds: Range<Int>) -> EventDataTable {
////        let slicedData = data.map { Array($0[bounds]) }
////        return try! EventDataTable(data: slicedData)
//        fatalError("Not implemented")
//    }

    
}
