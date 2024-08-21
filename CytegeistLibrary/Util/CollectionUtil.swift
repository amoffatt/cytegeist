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


// For a type having an implementing RandomAccessCollection, but also having
// an internal RAC storage, this protocol and extension forwards the key
// indexing functions to that internal collection
public protocol BackedRandomAccessCollection: RandomAccessCollection where
    Index == BackingCollection.Index,
//    SubSequence == BackingCollection.SubSequence,
    Indices == BackingCollection.Indices

{
    associatedtype BackingCollection:RandomAccessCollection
    
    // RandomAccessCollection Indices will be provided by this internal collection
    var _indexBacking:BackingCollection { get }

}

extension BackedRandomAccessCollection {
    public var startIndex: Index {
         _indexBacking.startIndex
    }

    public var endIndex: Index {
        _indexBacking.endIndex
    }
    
    public var count:Int {
        _indexBacking.count
    }
    
//    public subscript(position: Int) -> EventData {
//        precondition(position >= startIndex && position < endIndex, "Index out of bounds")
//        let values = data.map { $0[position] }
//        return EventData(id: position, values: values)
//    }
//
//    public subscript(bounds: Range<Int>) -> EventDataTable {
//        let slicedData = data.map { Array($0[bounds]) }
//        return try! EventDataTable(data: slicedData)
////        return slicedData
//    }
    
    public func index(after i: Index) -> Index {
        return _indexBacking.index(after: i)
    }

    public func index(before i: Index) -> Index {
        return _indexBacking.index(before: i)
    }
}


