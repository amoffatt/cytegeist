//
//  Transient.swift
//  CObservation
//
//  Created by AM on 11/6/24.
//

@propertyWrapper
public struct Transient<T> {
    public var wrappedValue: T
    
    public init(wrappedValue: T) {    self.wrappedValue = wrappedValue   }
    // public init(from decoder: Decoder) throws {  self.wrappedValue = nil  }
    // public func encode(to encoder: Encoder) throws {   }   // Do nothing
}
