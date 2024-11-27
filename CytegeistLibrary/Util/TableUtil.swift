//
//  Tables.swift
//  CytegeistLibrary
//
//  Created by Aaron Moffatt on 8/21/24.
//

import Foundation
import SwiftUI

public struct TableColumnField<RowValue> : Identifiable, Hashable where RowValue:Identifiable{
    public static func == (lhs: TableColumnField, rhs: TableColumnField) -> Bool {
        lhs.id == rhs.id
    }
    
//    public var order: SortOrder = .forward
    
    public var id: String { name }
    public let name:String
    public var hidden = false
    
//    public let keyPath: (RowValue) -> String
    public let keyPath: KeyPath<RowValue, String>

    public init(_ name:String, _ keyPath: KeyPath<RowValue, String>) {
        self.name = name
        self.keyPath = keyPath
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    public func value(from item: RowValue) -> String {
        item[keyPath:keyPath]
    }
    
    public func defaultColumn() -> TableColumn<RowValue, KeyPathComparator<RowValue>, Text, Text> {
        return TableColumn(name, value: keyPath) { item in
            let s = value(from: item)
            Text(s)
        }
    }

//    public func compare(_ lhs: RowValue, _ rhs: RowValue) -> ComparisonResult {
//        String.StandardComparator.lexical.compare(getter(lhs), getter(rhs))
//    }
}

