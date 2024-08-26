//
//  MathUtil.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/14/24.
//

import Foundation


public extension Collection where Element: AdditiveArithmetic {
    func sum() -> Element {
        reduce(Element.zero, +)
    }
}

public func clamp<T:Comparable>(_ x: T, min:T, max:T) -> T {
    x < min ? min
        : x > max ? max : x
}

public func clamp01<T:Numeric&Comparable>(_ x:T) -> T {
    clamp(x, min: 0, max: 1)
}

public extension UInt8 {
    static func fromUnitFloat(_ value:Float) -> UInt8 {
        UInt8(clamp01(value) * 255 + 0.5)
    }
    
    // Convert to float in range 0...1
    var unitFloat:Float {
        Float(self) / 255.0
    }
}


public struct PValue : Codable  //ClosedRange<Double> { (0.0...1.0) }       // 0...1 restricted float
{
    public static let zero = PValue(0)
    public static let one = PValue(1)
    
    public var p: Double  //ClosedRange<Double> { (0.0...1.0) }
    public init(_ value: Double)
    {
        p = value
    }
    
    public var inverted: PValue { PValue(1 - p) }
}

//public protocol AxisNormalizer: Hashable, Equatable {
//    
//    var min: Float { get }
//    var max: Float { get }
//    
//    func normalize(_ x:Float) -> Float
//    func unnormalize(_ x:Float) -> Float
//}


//public struct MutableRange<T:Comparable> {
//    public var lowerBound: T
//    public var upperBound: T
//
//    public var range: Range<T> {
//        return lowerBound..<upperBound
//    }
//}
//public extension Range {
//    var mutable: MutableRange<Bound> {
//        .init(lowerBound:lowerBound, upperBound:upperBound)
//    }
//}
//
//public struct MutableClosedRange<T:Comparable> {
//    public var lowerBound: T
//    public var upperBound: T
//
//    public var range: ClosedRange<T> {
//        return lowerBound...upperBound
//    }
//}


public extension ClosedRange where Bound: Strideable {
//    var mutable: MutableClosedRange<Bound> {
//        .init(lowerBound:lowerBound, upperBound:upperBound)
//    }
    
    func update(lowerBound:Bound? = nil, upperBound:Bound? = nil) -> ClosedRange<Bound> {
        (lowerBound ?? self.lowerBound)...(upperBound ?? self.upperBound)
    }
    
    func within(_ range:Range<Bound>) -> Bool {
        lowerBound >= range.lowerBound && upperBound < range.upperBound
    }
    
    func within(_ range:ClosedRange<Bound>) -> Bool {
        lowerBound >= range.lowerBound && upperBound <= range.upperBound
    }
}
