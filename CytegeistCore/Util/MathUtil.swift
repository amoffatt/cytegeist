//
//  MathUtil.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/14/24.
//


extension Collection where Element: AdditiveArithmetic {
    public func sum() -> Element {
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


public protocol AxisNormalizer {
    
    var min: Float { get }
    var max: Float { get }
    
    func normalize(_ x:Float) -> Float
    func unnormalize(_ x:Float) -> Float
}

public struct LinearAxisNormalizer : AxisNormalizer {
    
    public static let unit:AxisNormalizer = LinearAxisNormalizer(min:0, max:1)
    
    public let min: Float
    public let max: Float
    public let span: Float
    
    public init(min: Float, max: Float) {
        self.min = min
        self.max = max
        self.span = max - min
    }
    
    public func normalize(_ x: Float) -> Float {
        clamp01((x - min) / span)
    }
    
    public func unnormalize(_ x: Float) -> Float {
        clamp01(x) * span + min
    }
}


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
