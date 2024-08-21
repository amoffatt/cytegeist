//
//  Histogram.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 7/28/24.
//

import Foundation
import SwiftUI
import CytegeistLibrary

//public protocol Dim {
//    associatedtype ArraySize:NDArraySize
//    associatedtype Axes = SIMD where Scalar
//    associatedtype Coord
//    static var dimensions:Int { get }
//}

public protocol Dim<Axes, Strings, IntCoord, FloatCoord, Data> where
Axes:Tuple<AxisNormalizer>,
Strings:Tuple<String>,
IntCoord:Tuple<Int>,
FloatCoord:Tuple<Float>,
Data:Tuple<[Float]>
{
    
    associatedtype Axes
    associatedtype Strings
    
//    associatedtype Size = any Tuple<Int>
    associatedtype IntCoord
    associatedtype FloatCoord
    associatedtype Data
    
    static func inlineArraySize(size:IntCoord) -> Int
    
    static func pointToNDIndex(point:FloatCoord, axes:Axes, arraySize:IntCoord) -> IntCoord
    static func inlineArrayIndex(ndIndex:IntCoord, arraySize:IntCoord) -> Int
    
    static func count(data:Data) -> Int
    static func value(in data:Data, at index:Int) -> FloatCoord
}



public struct _1D : Dim {
    
    public typealias Axes = Tuple1<AxisNormalizer>
    public typealias Strings = Tuple1<String>
    public typealias IntCoord = Tuple1<Int>
    public typealias FloatCoord = Tuple1<Float>
    public typealias Data = Tuple1<[Float]>
    
    public static func inlineArraySize(size: Tuple1<Int>) -> Int {
        size.x
    }
    
    public static func inlineArrayIndex(ndIndex: Tuple1<Int>, arraySize: Tuple1<Int>) -> Int {
        precondition((0..<arraySize.x).contains(ndIndex.x))
        return ndIndex.x
    }
    
    public static func count(data: Tuple1<[Float]>) -> Int {
        data.x.count
    }
    
    public static func value(in data: Tuple1<[Float]>, at index: Int) -> Tuple1<Float> {
        .init(data.x[index])
    }
    
    public static func pointToNDIndex(point: Tuple1<Float>, axes: Tuple1<AxisNormalizer>, arraySize:Tuple1<Int>) -> Tuple1<Int> {
        let bin = axes.x.normalize(point.x) * Float(arraySize.x)
        return .init(Int(bin))
    }

}


public struct _2D : Dim {
    public typealias Axes = Tuple2<AxisNormalizer>
    public typealias Strings = Tuple2<String>
    public typealias IntCoord = Tuple2<Int>
    public typealias FloatCoord = Tuple2<Float>
    
    public static func inlineArraySize(size: Tuple2<Int>) -> Int {
        size.x * size.y
    }
    
    public static func inlineArrayIndex(ndIndex: Tuple2<Int>, arraySize: Tuple2<Int>) -> Int {
        precondition((0..<arraySize.x).contains(ndIndex.x))
        precondition((0..<arraySize.y).contains(ndIndex.y))
        
        return ndIndex.y * arraySize.x + ndIndex.x
    }
    
    public static func count(data: Tuple2<[Float]>) -> Int {
        data.x.count
    }
    
    public static func value(in data: Tuple2<[Float]>, at index: Int) -> Tuple2<Float> {
        .init(data.x[index], data.y[index])
    }
    
    public static func pointToNDIndex(point: Tuple2<Float>, axes: Tuple2<AxisNormalizer>, arraySize:Tuple2<Int>) -> Tuple2<Int> {
        let binX = axes.x.normalize(point.x) * Float(arraySize.x)
        let binY = axes.y.normalize(point.y) * Float(arraySize.y)
        return .init(Int(binX), Int(binY))
    }
}

public protocol Tuple<Value>: Hashable where Value:Hashable {
    associatedtype Value
    
    var x: Value { get }    // Every tuple will at least have a first/x value
    
    var values:[Value] { get }
    
    static func from(_ values:[Value]) -> Self
    
    func map<ResultValue>(_ f: (Value) -> ResultValue) -> Self where Self.Value == ResultValue
}

public struct Tuple1<Value> : Tuple where Value:Hashable {
    public static func from(_ values: [Value]) -> Tuple1<Value> {
        precondition(values.count >= 1)
        return .init(values[0])
    }
    
    public let x:Value
    public var values: [Value] { [x] }
    
    public init(_ x: Value) { self.x = x }
    
    public func map<ResultValue>(_ f: (Value) -> ResultValue) -> Tuple1<ResultValue> {
        Tuple1<ResultValue>(f(x))
    }
    
}


public struct Tuple2<Value> : Tuple where Value:Hashable {
    public static func from(_ values: [Value]) -> Tuple2<Value> {
        precondition(values.count >= 2)
        return .init(values[0], values[2])
    }

    public let x:Value
    public let y:Value
    
    public var values:[Value] { [ x, y ]}
    
    public init(_ x: Value, _ y: Value) {
        self.x = x
        self.y = y
    }
    
    public func map<ResultValue>(_ f: (Value) -> ResultValue) -> Tuple2<ResultValue> {
        return Tuple2<ResultValue>(f(x), f(y))
    }
}

public struct Tuple3<Value> {
    public let x:Value
    public let y:Value
    public let z:Value
}


//
//public class _1D : Dim {
//    public typealias Coord = Coord1D<Float>
//    public typealias Size = Coord1D<Int>
//
//    public static var dimensions:Int { 1 }
//}
//
//public class _2D : Dim {
//    public typealias Coord = Tuple2<Float>
//    public typealias ArraySize = Tuple2<Int>
//    public typealias Axes = Tuple2<AxisNormalizer>
//
//    public static var dimensions:Int { 2 }
//}

//extension Tuple2<Int> : NDArraySize, NDIndex {
//    public var inlineArraySize: Int {
//        x * y
//    }
//   
//}

//public protocol _1D : Dim {
//    public static var dimensions:Int { 1 }
//}

//public extension Dim {
//    
//}


//public protocol NDArraySize {
//    var inlineArraySize:Int { get }
//}
//
//public protocol NDIndex {
////    func inlineArrayIndex(arraySize:D) -> Int
//}

//public protocol Coord<Value> {
//    associatedtype Dimension: Dim
//    associatedtype Value: Numeric
//}
//
//public struct Coord1D<Value:Numeric>: Coord {
//    public typealias Dimension = _1D
//    
//    public let x:Value
//}
//
//extension Coord1D<Int> : NDIndex where D == _1D {
    
//    public typealias D = _1D
    
//    public func arrayIndex(arraySize: Coord1D<Int>) -> Int { arraySize.x }

    
//}

//public struct Coord2D<Value:Numeric>: Coord {
////    public static var dimensions:Int { 2 }
//    public typealias Dimension = _2D
//
//    public let x:Value
//    public let y:Value
//}
//
//extension Coord2D<Int> : NDIndex {
//    public var singleDimIndex: Int { x }
//}

//public struct HistogramData<D:Dim> {
//    public var dimensions:Int { D.dimensions }
//    
//    private let bins:[Int]
//    internal let axes:D.Axes
//    internal let resolution:D.Size
//    public let countAxis:AxisNormalizer?
//    
//    public init(bins: [Int], axes: D.Axes, resolution: D.ArraySize, countAxis: AxisNormalizer? = nil) {
//        self.bins = bins
////        guard axes.count == dimensions else {
////            fatalError("Wrong number of AxisNormalizers (\(axes.count) for histogram of dimension \(dimensions)")
////        }
//        self.axes = axes
//        
////        guard resolution.count == dimensions else {
////            fatalError("Wrong dimension of resolution (\(resolution.count) for histogram of dimension \(dimensions)")
////        }
//        self.resolution = resolution
//        
//        self.countAxis = countAxis
//    }
//    
//    public func count(coord: D.Coord) -> Int {
//        bins[clamp(bin, min:0, max:resolution-1)]
//    }
//    
//    
//
//    private static func defaultCountAxis(bins:[Int]) -> AxisNormalizer {
//        var maxValue = max(1, bins.max() ?? 1)
//        return LinearAxisNormalizer(min: 0, max: Float(maxValue))
//    }
//}

//public protocol AxesTuple<D>: Tuple where Value == any AxisNormalizer {
//    associatedtype D
//}

public struct HistogramData<D:Dim> {
//    public typealias Axes = AxesTuple
    
    public let bins:[UInt8]
    public let maxCount: Int
    
    public let axes:D.Axes
    public let countAxis:AxisNormalizer?
    
    public var size:D.IntCoord
    
    private let binScaling:Double
    
    public func normalizedCount(bin: D.IntCoord) -> Float {
        let index = D.inlineArrayIndex(ndIndex: bin, arraySize: size)
        return normalizedCount(bin: index)
    }
    
    public func normalizedCount(bin: Int) -> Float {
        return bins[bin].unitFloat
    }

    public init(bins: [Int], size: D.IntCoord, axes: D.Axes, countAxis: AxisNormalizer? = nil) {
        self.maxCount = bins.max() ?? 0
        let binScaling = Double(max(1, maxCount)) / 255.0
        self.bins = bins.map { UInt8(Double($0) / binScaling) }
        self.binScaling = binScaling
        
        self.axes = axes
        self.size = size
        self.countAxis = countAxis ?? defaultCountAxis(maxCount: maxCount)
    }
    
    public init(data: D.Data, size: D.IntCoord, axes: D.Axes, countAxis: AxisNormalizer? = nil) {
        var bins = Array(repeating: 0, count: D.inlineArraySize(size:size))
        
        for i in 0..<D.count(data: data) {
            let point = D.value(in: data, at: i)
            let ndBin = D.pointToNDIndex(point: point, axes: axes, arraySize: size)
            let bin = D.inlineArrayIndex(ndIndex:ndBin, arraySize: size)
            bins[bin] += 1
        }
        
        self.init(bins:bins, size:size, axes:axes, countAxis:countAxis)
    }
}



fileprivate func defaultCountAxis(maxCount:Int?) -> AxisNormalizer {
//        var maxValue = max(1, bins.max() ?? 1)
    let maxCount = max(1, maxCount ?? 0)
    return .linear(min: 0, max: Float(maxCount))
}





//public struct Histogram2DData {
//    public typealias Element = (x:Int, y:Int, count:Int)
//    public typealias SubSequence = Array<Int>.SubSequence
//    
//    
//    public var bins:[Int]
//    public let axes:Tuple2<AxisNormalizer>
//    public let countAxis:AxisNormalizer?
//    
////    public var _backing: [Int] { bins }
//    
//    public var resolution:Tuple2<Int>
//    
//    public func count(bin: Tuple2<Int>) -> Int {
//        return bins[binIndex(bin:bin)]
//    }
//    
//    public func count(point: Tuple2<Float>) -> Int {
//        return bins[binIndex(point:point)]
//    }
//    
//    public init(resolution: Tuple2<Int>, axes: Tuple2<AxisNormalizer>, countAxis: AxisNormalizer? = nil) {
//        self.bins = Array(repeating: 0, count: resolution.inlineArraySize)
//        self.axes = axes
//        self.resolution = resolution
//        self.countAxis = countAxis ?? defaultCountAxis(maxCount: bins.max())
//    }
//    
//    public init(data: Tuple2<[Float]>, resolution: Tuple2<Int>, axes: Tuple2<AxisNormalizer>, countAxis: AxisNormalizer? = nil) {
//        guard data.values.allSameLength() else {
//            fatalError("All parameters not equal length")
//        }
//        
//        self.init(
//            resolution: resolution,
//            axes: axes,
//            countAxis: countAxis)
//        
//        let dataCount = data.x.count
//        for i in 0..<dataCount {
//            let bin = binIndex(
//                point:.init(data.x[i], data.y[i])
//            )
//            self.bins[bin] += 1
//        }
//        
//    }
//    
//    func binIndex(bin:Tuple2<Int>) -> Int {
//        let x = clamp(bin.x, min:0, max: resolution.x - 1)
//        let y = clamp(bin.y, min:0, max: resolution.y - 1)
//        let binIndex = y * resolution.x + x
//        return binIndex
//    }
//    
//    func binIndex(point:Tuple2<Float>) -> Int {
//        let bin = Tuple2(
//            Int(axes.x.normalize(point.x) * Float(resolution.x)),
//            Int(axes.y.normalize(point.y) * Float(resolution.y))
//        )
//        return binIndex(bin:bin)
//    }
//    
//
//    func bin(bin1d:Int) -> Tuple2<Int> {
//        return Tuple2(bin1d % resolution.x, bin1d / resolution.x)
//    }
//    
//    func binPoint(bin1d:Int) -> Tuple2<Float> {
//        let bin = bin(bin1d:bin1d)
//        
//        return Tuple2(
//            axes.x.unnormalize(Float(bin.x) / Float(resolution.x)),
//            axes.y.unnormalize(Float(bin.y) / Float(resolution.y))
//        )
//    }
//
//}


extension HistogramData<_2D> {
    func toImage(colormap:Colormap) -> Image? {
        // TODO OPTIMIZE
        // Set pixels with UInt32 array instead of UInt8
        // Colormap would cache UInt32 color values.
        // Init pixel values with min colormap value, and only compute colormap value if bin is not 0
        
        let byteCount = bins.count * 4 // 4 bytes per pixel (RGBA)
        var pixels = [UInt8](repeating: 0, count: byteCount)
//        let minColor = colormap.uint8Lookup[0]
        
        for y in 0..<size.y {
            for x in 0..<size.x {
                let bin = (y * size.x + x)
                let value = normalizedCount(bin: bin)
                let color = colormap.colorUInt8(at: value)

                let pixelOffset = bin * 4
                pixels[pixelOffset] = color.x
                pixels[pixelOffset + 1] = color.y
                pixels[pixelOffset + 2] = color.z
                pixels[pixelOffset + 3] = color.w
            }
        }
        
        let cgImage = pixels.withUnsafeBufferPointer { pointer in
            let context = CGContext(
                data: UnsafeMutableRawPointer(mutating: pointer.baseAddress),
                width: size.x,
                height: size.y,
                bitsPerComponent: 8,
                bytesPerRow: size.x * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
            return context?.makeImage()
        }
        
        return cgImage?.image
    }
}
