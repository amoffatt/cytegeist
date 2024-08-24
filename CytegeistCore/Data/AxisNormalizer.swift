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
    case log(base:Double)
//    case biex(a:Float, b:Float)
}

public struct AxisNormalizer: Hashable, Codable {
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
            let tickInterval = niceNumber(roughTickInterval, round: true)
            
            let minTick = floor(min / tickInterval) * tickInterval
            let maxTick = ceil(max / tickInterval) * tickInterval
            
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

func niceNumber(_ x: Double, round: Bool) -> Double {
    let exp = floor(log10(x))
    let f = x / pow(10, exp)
    var nf: Double
    
    if round {
        if f < 1.5 {
            nf = 1
        } else if f < 3 {
            nf = 2
        } else if f < 7 {
            nf = 5
        } else {
            nf = 10
        }
    } else {
        if f <= 1 {
            nf = 1
        } else if f <= 2 {
            nf = 2
        } else if f <= 5 {
            nf = 5
        } else {
            nf = 10
        }
    }
    
    return nf * pow(10, exp)
}
