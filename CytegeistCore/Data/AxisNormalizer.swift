//
//  AxisNormalizer.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 8/22/24.
//

import Foundation
import CytegeistLibrary

public enum AxisScaleType: Hashable {
    case linear
    case log(base:ValueType)
    case biex(_ transform: Logicle)
}

public struct AxisNormalizer: Hashable, Codable {
    public static let none = AxisNormalizer(0, 1, .linear, { $0 }, { $0 }, { _ in [] })
    
    public static func linear(minVal:Double, maxVal:Double) -> AxisNormalizer {

        let span = maxVal - minVal
        func normalize(_ value: Double) -> Double {    clamp01((value - minVal) / span)    }
        func unnormalize(_ value: Double) -> Double {  clamp01(value) * span + minVal     }

        func calculateTickMarks(desiredTicks: Int) -> [MajorAxisTick] {
            let range = maxVal - minVal
            let roughTickInterval = range / Double(desiredTicks - 1)
            let (tickInterval, minorTickCount) = niceNumber(roughTickInterval, round: false)
            
            let minTick = floor(minVal / tickInterval) * tickInterval
            let maxTick = floor(maxVal / tickInterval) * tickInterval      // AT - was ceil
            
            var ticks: [Double] = []
            var tick = minTick
            while tick <= maxTick {
                ticks.append(tick)
                tick += tickInterval
            }
            
            return ticks.map { value in
                let minorTickInterval = tickInterval / Double(minorTickCount + 1)
                let minorTicks = (1...minorTickCount).compactMap { i in
                    let tickValue = value + Double(i) * minorTickInterval
                    if tickValue >= minVal && tickValue <= maxVal {
                        return Float(normalize(tickValue))
                    }
                    return nil
                }

                return .init(
                    normalizedValue: Float(normalize(value)),
                    label: String(format:"%.0fK", value / 1000.0),
                    minorTicks: minorTicks)
            }
        }

        return .init(
            minVal, maxVal, .linear,
            normalize, unnormalize,
            calculateTickMarks
        )
    }
    
    public static func log(minVal:Double, maxVal:Double, base:Double = 10) -> AxisNormalizer {
        let logBase = Darwin.log(base)
        let logMin = Darwin.log(minVal) / logBase
        let logMax = Darwin.log(maxVal) / logBase
        let logSpan = logMax - logMin
        
        func normalize(_ value: Double) -> Double {
            let clamped = clamp(value, min:minVal, max:maxVal)
            let normalized = (Darwin.log(clamped) / logBase - logMin) / logSpan
            return normalized
        }
        
        func unnormalize(_ value: Double) -> Double {
            let clamped = clamp01(value)
            let logValue = (clamped * logSpan) + logMin
            return pow(base, logValue)
        }
        
        func calculateTickMarks(desiredTicks: Int) -> [MajorAxisTick] {
            
            let ticks: [Double] = [1, 10, 100, 1000, 10000]//, 100000]
            return ticks.map { value in
                let minorTickInterval = base
                let minorTicks = (2...9).compactMap { i in
                    let tickValue = value * Double(i)// * minorTickInterval
                    if tickValue >= minVal && tickValue <= maxVal {
                        return Float(normalize(tickValue))
                    }
                    return nil
                }
                
                return .init(
                    normalizedValue: Float(normalize(value)),
                    label: String(format:"10^%.0f", Darwin.log(value) / logBase),
                    minorTicks: minorTicks)
            }
        }
        
        return .init(
            minVal, maxVal, .log(base:base),
            normalize, unnormalize,
            calculateTickMarks
        )
    }
    // TODO --- doesn't use the logicle function.  Currently is hacked copy of log
    // see MathUtil
    
    public static func logicle(minVal:Double, maxVal:Double) -> AxisNormalizer {
        let transform = Logicle(T:0, w:0, m:0)
        let base:Double = 10
        let logBase = Darwin.log(base)
        let logMin = Darwin.log(minVal) / logBase
        let logMax = Darwin.log(maxVal) / logBase
        let logSpan = logMax - logMin
        
        func normalize(_ value: Double) -> Double {
            let clamped = clamp(value, min:minVal, max:maxVal)
            let normalized = (Darwin.log(clamped) / logBase - logMin) / logSpan
            return normalized
        }
        
        func unnormalize(_ value: Double) -> Double {
            let clamped = clamp01(value)
            let logValue = (clamped * logSpan) + logMin
            return pow(base, logValue)
        }
        
        func calculateTickMarks(desiredTicks: Int) -> [MajorAxisTick] {
 
            let ticks: [Double] = [0, 100, 1000, 10000, 100000]
            return ticks.map { value in
                let minorTickInterval = 10.0
                let minorTicks = (2...9).compactMap { i in
                    let tickValue = value * Double(i) * minorTickInterval
                    if tickValue >= minVal && tickValue <= maxVal {
                        return Float(normalize(tickValue))
                    }
                    return nil
                }
                let labelStr = (value == 0) ? "0" : String(format:"10^%.0f", Darwin.log(value) / logBase)
                return .init(
                    normalizedValue: Float(normalize(value)),
                    label: labelStr,
                    minorTicks: minorTicks)
            }
        }
        return .init(
            minVal, maxVal, .log(base:base),
            normalize, unnormalize,
            calculateTickMarks
        )
    }
    
    public static func == (lhs: AxisNormalizer, rhs: AxisNormalizer) -> Bool {
        lhs.minVal == rhs.minVal && lhs.maxVal == rhs.maxVal && lhs.type == rhs.type
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(minVal)
        hasher.combine(maxVal)
        hasher.combine(type)
    }
    
    public let minVal: Double
    public let maxVal: Double
    
    public let type:AxisScaleType
    public var span: Double { maxVal - minVal }
    
    public let normalize:(_ x:Double) -> Double
    public let unnormalize:(_ x:Double) -> Double
    public let tickMarks:(_ desiredCount: Int) -> [MajorAxisTick]
    
    fileprivate init(_ minVal: Double, _ maxVal: Double, _ type: AxisScaleType,
                     _ normalize: @escaping (Double) -> Double,
                     _ unnormalize: @escaping (Double) -> Double,
                     _ ticks: @escaping (_ count: Int) -> [MajorAxisTick]
    ) {
        self.minVal = minVal
        self.maxVal = maxVal
        self.type = type
        self.normalize = normalize
        self.unnormalize = unnormalize
        self.tickMarks = ticks
    }
    
    public init(from decoder: any Decoder) throws {
        fatalError()
    }
    
    public func encode(to encoder: any Encoder) throws {
        fatalError()
    }
    
}


public struct MajorAxisTick: Identifiable {
    public var id: Float { normalizedValue }
    
    public var normalizedValue: Float
    public var label: String
    
    public var minorTicks:[Float]
}

//public class LinearAxis {
//}
//---------------------------------------------------------------------------
func niceNumber(_ x: Double, round: Bool) -> (interval:Double, minorTicks:Int) {
    let exp = floor(log10(x))
    let f = x / pow(10, exp)
    var nf: Double
    var minorTicks: Int = 4
    
    if round {
        if f < 1.5      {  nf = 1
        } else if f < 3 {  nf = 2; minorTicks = 3
        } else if f < 7 {  nf = 5;
        } else {          nf = 10
        }
    } else {
        if f <= 1 {        nf = 1
        } else if f <= 2 { nf = 2; minorTicks = 3
        } else if f <= 5 { nf = 5;
        } else {           nf = 10
        }
    }
    
    return (nf * pow(10, exp), minorTicks)
}
    //---------------------------------------------------------------------------

public extension CGPoint {
    func unnormalize(_ normalizers:Tuple2<AxisNormalizer?>) -> CGPoint {
        .init(x:normalizers.x?.unnormalize(x) ?? .nan,
              y:normalizers.y?.unnormalize(y) ?? .nan)
    }
    
    func normalize(_ normalizers:Tuple2<AxisNormalizer?>) -> CGPoint {
        .init(x:normalizers.x?.normalize(x) ?? .nan,
              y:normalizers.y?.normalize(y) ?? .nan)
    }
    
    func unnormalize(_ normalizers:Tuple2<AxisNormalizer>) -> CGPoint {
        .init(x:normalizers.x.unnormalize(x),
              y:normalizers.y.unnormalize(y))
    }
    
    func normalize(_ normalizers:Tuple2<AxisNormalizer>) -> CGPoint {
        .init(x:normalizers.x.normalize(x),
              y:normalizers.y.normalize(y))
    }
}
    //---------------------------------------------------------------------------
public extension CGRect {
    func unnormalize(_ normalizers:Tuple2<AxisNormalizer?>) -> CGRect {
        .init(from: min.unnormalize(normalizers),
              to:max.unnormalize(normalizers))
    }
    
    func normalize(_ normalizers:Tuple2<AxisNormalizer?>) -> CGRect {
        .init(from: min.normalize(normalizers),
              to: max.normalize(normalizers))
    }
}

    //---------------------------------------------------------------------------
public extension Tuple2<AxisNormalizer?> {
    var nonNil: Tuple2<AxisNormalizer> {
        map { $0! }
    }
}

//public extension Ellipsoid {
//    func normalize(_ normalizers:Tuple2<AxisNormalizer?>) -> Ellipsoid {
//        with(vertex0: vertex0.normalize(normalizers),
//             vertex1: vertex1.normalize(normalizers))
//    }
//    
//    func unnormalize(_ normalizers:Tuple2<AxisNormalizer?>) -> Ellipsoid {
//        with(vertex0: vertex0.unnormalize(normalizers),
//             vertex1: vertex1.unnormalize(normalizers))
//    }
//}
