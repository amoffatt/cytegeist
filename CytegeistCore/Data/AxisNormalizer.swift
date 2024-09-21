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
    
    public static func linear(min:Double, max:Double) -> AxisNormalizer {
        let span = max - min
        
        func normalize(_ value: Double) -> Double {
            clamp01((value - min) / span)
        }
        
        func unnormalize(_ value: Double) -> Double {
            clamp01(value) * span + min
        }

        func calculateTickMarks(desiredTicks: Int) -> [MajorAxisTick] {
            let range = max - min
            let roughTickInterval = range / Double(desiredTicks - 1)
            let tickInterval = niceNumber(roughTickInterval, round: false)
            
            let minTick = floor(min / tickInterval) * tickInterval
            let maxTick = floor(max / tickInterval) * tickInterval      // AT - was ceil
            
            var ticks: [Double] = []
            var tick = minTick
            while tick <= maxTick {
                ticks.append(tick)
                tick += tickInterval
            }
            
            return ticks.map { value in
                .init(
                    normalizedValue: Float(normalize(value)),
                    label: String(value),
                    minorTicks: [])
            }
        }

        return .init(
            min, max, .linear,
            normalize, unnormalize,
            calculateTickMarks
        )
    }
    
    public static func log(min:Double, max:Double, base:Double = 10) -> AxisNormalizer {
        let logBase = Darwin.log(base)
        let logMin = Darwin.log(min) / logBase
        let logMax = Darwin.log(max) / logBase
        let logSpan = logMax - logMin
        
        func normalize(_ value: Double) -> Double {
            let clamped = clamp(value, min:min, max:max)
            let normalized = (Darwin.log(clamped) / logBase - logMin) / logSpan
            return normalized
        }
        
        func unnormalize(_ value: Double) -> Double {
            let clamped = clamp01(value)
            let logValue = (clamped * logSpan) + logMin
            return pow(base, logValue)
        }
        
        func calculateTickMarks(_ desiredCount: Int) -> [MajorAxisTick] {
            []
        }

        return .init(
            min, max, .log(base:base),
            normalize, unnormalize,
            calculateTickMarks
        )
    }
    
    public static func logicle(min:Double, max:Double) -> AxisNormalizer {
        let transform = Logicle(T:0, w:0, m:0)
        
        func calculateTickMarks(desiredTicks: Int) -> [MajorAxisTick] {
            []
        }
        
        return .init(
            min, max, .biex(transform),
            transform.logicle,
            transform.unnormalize,
            calculateTickMarks)
    }
    
    public static func == (lhs: AxisNormalizer, rhs: AxisNormalizer) -> Bool {
        lhs.min == rhs.min && lhs.max == rhs.max && lhs.type == rhs.type
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(min)
        hasher.combine(max)
        hasher.combine(type)
    }
    
    public let min: Double
    public let max: Double
    
    public let type:AxisScaleType
    public var span: Double { max - min }
    
    public let normalize:(_ x:Double) -> Double
    public let unnormalize:(_ x:Double) -> Double
    public let tickMarks:(_ desiredCount: Int) -> [MajorAxisTick]
    
    fileprivate init(_ min: Double, _ max: Double, _ type: AxisScaleType,
                     _ normalize: @escaping (Double) -> Double,
                     _ unnormalize: @escaping (Double) -> Double,
                     _ ticks: @escaping (_ count: Int) -> [MajorAxisTick]
    ) {
        self.min = min
        self.max = max
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

public class LinearAxis {
}
//---------------------------------------------------------------------------
func niceNumber(_ x: Double, round: Bool) -> Double {
    let exp = floor(log10(x))
    let f = x / pow(10, exp)
    var nf: Double
    
    if round {
        if f < 1.5      {  nf = 1
        } else if f < 3 {  nf = 2
        } else if f < 7 {  nf = 5
        } else {          nf = 10
        }
    } else {
        if f <= 1 {        nf = 1
        } else if f <= 2 { nf = 2
        } else if f <= 5 { nf = 5
        } else {           nf = 10
        }
    }
    
    return nf * pow(10, exp)
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
