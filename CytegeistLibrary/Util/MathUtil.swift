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



//public protocol AxisNormalizer: Hashable, Equatable {
//    
//    var min: Float { get }
//    var max: Float { get }
//    
//    func normalize(_ x:Float) -> Float
//    func unnormalize(_ x:Float) -> Float
//}

public enum AxisScaleType: Hashable {
    case linear
    case log(base:Float)
//    case biex(a:Float, b:Float)
}

public struct AxisNormalizer: Hashable {
    public static func linear(min:Float, max:Float) -> AxisNormalizer {
        let span = max - min
        
        return .init(
            min, max, .linear,
            normalize: {
                clamp01(($0 - min) / span)
            },
            unnormalize: {
                clamp01($0) * span + min
            }
        )
    }
    
    public static func log(min:Float, max:Float, base:Float = 10) -> AxisNormalizer {
        let logBase = Darwin.log(base)
        let logMin = Darwin.log(min) / logBase
        let logMax = Darwin.log(max) / logBase
        let logSpan = logMax - logMin

        return .init(
            min, max, .log(base:base),
            normalize: {
                let clamped = clamp($0, min:min, max:max)
                let normalized = (Darwin.log(clamped) / logBase - logMin) / logSpan
                return normalized
            },
            unnormalize: {
                let clamped = clamp01($0)
                let logValue = (clamped * logSpan) + logMin
                return pow(base, logValue)
            }
        )
    }

    
    
    
    public static func == (lhs: AxisNormalizer, rhs: AxisNormalizer) -> Bool {
        lhs.min == rhs.min && lhs.max == rhs.max && lhs.type == rhs.type
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(min)
        hasher.combine(max)
        hasher.combine(type)
    }
    
    public let min: Float
    public let max: Float
    
    public let type:AxisScaleType
    
    public let normalize:(_ x:Float) -> Float
    public let unnormalize:(_ x:Float) -> Float
    
    fileprivate init(_ min: Float, _ max: Float, _ type: AxisScaleType, normalize: @escaping (_: Float) -> Float, unnormalize: @escaping (_: Float) -> Float) {
        self.min = min
        self.max = max
        self.type = type
        self.normalize = normalize
        self.unnormalize = unnormalize
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
