//
//  CodableUtil.swift
//  CytegeistLibrary
//
//  Created by Aaron Moffatt on 8/21/24.
//

import Foundation


@propertyWrapper
public struct CodableIgnored<T>: Codable {
    public var wrappedValue: T?
    
    public init(wrappedValue: T?) {    self.wrappedValue = wrappedValue   }
    public init(from decoder: Decoder) throws {  self.wrappedValue = nil  }
    public func encode(to encoder: Encoder) throws {   }   // Do nothing
}

extension KeyedDecodingContainer {
    public func decode<T>(
        _ type: CodableIgnored<T>.Type,
        forKey key: Self.Key) throws -> CodableIgnored<T>
    {
        return CodableIgnored(wrappedValue: nil)
    }
}

extension KeyedEncodingContainer {
    public mutating func encode<T>(
        _ value: CodableIgnored<T>,
        forKey key: KeyedEncodingContainer<K>.Key) throws
    {
            // Do nothing
    }
}


public extension Hasher {
    mutating func combineMany(_ values: any Hashable...) {
        for x in values {
            self.combine(x)
        }
                    
    }
}
