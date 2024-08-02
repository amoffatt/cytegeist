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
