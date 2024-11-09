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

public func sort<T:Comparable>(_ a:T, _ b:T) -> (T, T) {
    if a > b {
        return (b, a)
    }
    return (a, b)
}

public func sqr<T:FloatingPoint>(_ x:T) -> T {
    x * x
}

public let twoPi = 2.0 * CGFloat.pi

public extension FloatingPoint {
    func ifNotFinite(_ newValue:Self) -> Self {
        self.isFinite ? self : newValue
    }
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

public extension Comparable {
//    func in(range: ClosedRange<Self>) -> Bool {
//        range.contains(self)
////        self < r
////        ? range.lowerBound
////        : self > max ? max : x
//    }
}
    //-----------------------------------------------------------------------

public struct PValue : Codable  //ClosedRange<Double> { (0.0...1.0) }       // 0...1 restricted float
{
    public static let zero = PValue(0)
    public static let one = PValue(1)
    
    public var p: Double  //ClosedRange<Double> { (0.0...1.0) }
    public init(_ value: Double)    {
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

    //-----------------------------------------------------------------------

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
    //-----------------------------------------------------------------------


public struct Logicle : Equatable, Hashable {
    static let maxLoops = 1000
    static let initPLowBound = 1e-3
    static let initPUpperBound = 1e6
    static let epsilon = 1e-12
    
    static func calculateP(w:Double) -> Double {
        var lowerBound = initPLowBound
        var upperBound = initPUpperBound
        var p = (upperBound + lowerBound) / 2
        var nCheck = maxLoops;
        
        while ((lowerBound + epsilon < upperBound) && (nCheck > 0)) {
            if (2.0 * p * log(p) / (p+1)) > w
            {     upperBound = p    }
            else    {      lowerBound = p    }
            p = (upperBound + lowerBound) / 2
            nCheck -= 1
        }
        return p;
    }

    var T: Double
    var w: Double
    var m: Double
    var p: Double
    
    public init(T: Double, w: Double, m: Double)
    {
            //      assert((T>0) && (w>0) && (m>0))
        self.T = T
        self.w = w
        self.m = m
        self.p = Self.calculateP(w:w)
    }
    
    public func logicle(_ x: Double) -> Double
    {
//        var lowerBound: Double = -T
//        var upperBound: Double = T
//        var r: Double = (upperBound + lowerBound) / 2
//        var nCheck = maxLoops
//        while (lowerBound + epsilon < upperBound && nCheck > 0)
//        {
//            if(s(y: r, firstTime: true) > x)
//            {    upperBound = r  }
//            else {   lowerBound = r     }
//            r = (upperBound + lowerBound) / 2
//            nCheck -= 1
//        }
//        return r;
        fatalError()
    }
    
    public func unnormalize(_ x: Double) -> Double {
        0.0
    }
    
        //-----------------------------------------------------------------------
    func s(y: Double) -> Double {    return s(y: y, firstTime: true)    }
    
    func  s(y: Double,  firstTime: Bool)  -> Double
    {
        if((y >= w) || (!firstTime))   {
            return T * exp(-(m-w)) * (exp(y-w) - p*p*exp(-(y-w)/p) + p*p - 1)
        }
        return -1.0 * s(y: w-y, firstTime: false);
    }
        //-----------------------------------------------------------------------
}

