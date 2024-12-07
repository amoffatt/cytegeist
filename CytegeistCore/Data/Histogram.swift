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

public protocol Dimensions<Axes, Strings, IntCoord, FloatCoord, Data> where
Axes:Tuple<AxisNormalizer>,
Strings:Tuple<String>,
IntCoord:Tuple<Int>,
FloatCoord:Tuple<ValueType>,
Data:Tuple<[ValueType]>
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
    static func inlineArrayToCoord(index:Int, axes:Axes, arraySize:IntCoord) -> FloatCoord

    static func count(data:Data) -> Int
    static func value(in data:Data, at index:Int) -> FloatCoord
}

func normalizedToArrayIndex(_ value:ValueType, arraySize:Int) -> Int {
    min(arraySize - 1, Int(value * ValueType(arraySize)))
}


public struct X : Dimensions {
    public typealias Axes = Tuple1<AxisNormalizer>
    public typealias Strings = Tuple1<String>
    public typealias IntCoord = Tuple1<Int>
    public typealias FloatCoord = Tuple1<ValueType>
    public typealias Data = Tuple1<[ValueType]>
    
    public static func inlineArraySize(size: Tuple1<Int>) -> Int {
        size.x
    }
    
    public static func inlineArrayIndex(ndIndex: IntCoord, arraySize: IntCoord) -> Int {
        precondition((0..<arraySize.x).contains(ndIndex.x))
        return ndIndex.x
    }
    
    public static func count(data: Data) -> Int {
        data.x.count
    }
    
    public static func value(in data: Data, at index: Int) -> FloatCoord {
        .init(data.x[index])
    }
    
    public static func pointToNDIndex(point: FloatCoord, axes:Axes, arraySize:IntCoord) -> Tuple1<Int> {
        let normalized = axes.x.normalize(Double(point.x))
        return .init(normalizedToArrayIndex(normalized, arraySize: arraySize.x))
    }
    
    public static func inlineArrayToCoord(index: Int, axes:Axes, arraySize:IntCoord) -> FloatCoord {
        let normalized = Double(index) / Double(arraySize.x)
        return .init(axes.x.unnormalize(normalized))
    }

}


public struct XY : Dimensions {
    public typealias Axes = Tuple2<AxisNormalizer>
    public typealias Strings = Tuple2<String>
    public typealias IntCoord = Tuple2<Int>
    public typealias FloatCoord = Tuple2<ValueType>
    public typealias Data = Tuple2<[ValueType]>

    public static func inlineArraySize(size: Tuple2<Int>) -> Int {
        size.x * size.y
    }
    
    public static func inlineArrayIndex(ndIndex: Tuple2<Int>, arraySize: Tuple2<Int>) -> Int {
        precondition((0..<arraySize.x).contains(ndIndex.x))
        precondition((0..<arraySize.y).contains(ndIndex.y))
        
        return ndIndex.y * arraySize.x + ndIndex.x
    }
    
    public static func inlineArrayToCoord(index: Int, axes:Axes, arraySize:IntCoord) -> FloatCoord {
        let normalizedX = Double(index % arraySize.x) / Double(arraySize.x)
        let normalizedY = Double(index / arraySize.x) / Double(arraySize.y)
        return .init(
            axes.x.unnormalize(normalizedX),
            axes.y.unnormalize(normalizedY)
        )
    }

    public static func count(data: Data) -> Int {
        data.x.count
    }
    
    public static func value(in data: Data, at index: Int) -> FloatCoord {
        .init(data.x[index], data.y[index])
    }
    
    public static func pointToNDIndex(point: FloatCoord, axes: Tuple2<AxisNormalizer>, arraySize:Tuple2<Int>) -> Tuple2<Int> {
        let x = axes.x.normalize(Double(point.x))
        let y = axes.y.normalize(Double(point.y))
        return .init(normalizedToArrayIndex(x, arraySize: arraySize.x),
                     normalizedToArrayIndex(y, arraySize: arraySize.y))
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
    public func map<ResultValue>(_ f: (Value) -> ResultValue) -> Tuple1<ResultValue> { Tuple1<ResultValue>(f(x)) }
    
}

extension Tuple1:Codable where Value:Codable {}


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
extension Tuple2:Codable where Value:Codable {}

public struct Tuple3<Value> {
    public let x:Value
    public let y:Value
    public let z:Value
}

extension Tuple3:Codable where Value:Codable {}


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

public struct BasicHistogramStats {
    public var stdev: Double
    public var cv: Double
    public var mean: Double
    public var meanHeight: Double
    public var median: Double
    // Also quartiles and robust CV?

    
    public init(data:HistogramData<X>)
    {
        let totalCount = data.totalCount
        let bins = data.bins
        
        // TODO figure out if this should be used
        let weightedBins = data.counts.map { bin, count in bin.x * Double(count) }
        self.mean = weightedBins.sum() / totalCount
        self.meanHeight = data.totalCount / Double(data.bins.count)
        self.median = data.percentile(0.5)
        
//        let halfSum = totalCount / 2.0
//        var sum = 0.0
//        for bin in 0..<bins.count {
//            sum += bins[bin ]
//            if sum > halfSum {
//                let diff = bins[bin] - bins[bin-1]
//                let ratio = (sum - halfSum) / (sum - diff)
//                self.median = Double(bin) - ratio
//                break
//            }   }
            // σ = √[(Σ(x - μ)^2) / (n - 1)]
        
        var sum = 0.0
        for bin in 0..<bins.count {
            sum += (mean - bins[bin]) * (mean - bins[bin])
        }
        self.stdev = sqrt(sum / Double( bins.count-1))
        self.cv = stdev / mean * 100.0
    }
    

}

public struct HistogramData<D:Dimensions> {
        //    public typealias Axes = AxesTuple
    
    public var bins:[Double]
    public var mode: Int?
    public var modeHeight: Double = 0.0
    public var totalCount: Double
    public var normalizeCoeff: Double

    public let axes:D.Axes
    public var countAxis:AxisNormalizer?
    
    public var size:D.IntCoord
    
        //    private let mode:Float
    
    public func normalizedCount(bin: D.IntCoord) -> Double {
        let index = D.inlineArrayIndex(ndIndex: bin, arraySize: size)
        return normalizedCount(bin: index)
    }
    
    public func normalizedCount(bin: Int) -> Double {
        return bins[bin] * normalizeCoeff
    }
    
    public var counts:some Sequence<(value:D.FloatCoord, count:Double)> {
        bins.enumerated().map { index, count in
            (D.inlineArrayToCoord(index:index, axes:axes, arraySize:size), count)
        }
    }

    public init(bins: [Double], size: D.IntCoord, axes: D.Axes, countAxis: AxisNormalizer? = nil) {
        var sum = 0.0
        for bin in 0..<bins.count {
            sum += bins[bin]
            if bins[bin] > modeHeight {
                mode = bin
                modeHeight = bins[bin]
            }
        }
        totalCount = sum
        normalizeCoeff = 1.0 / max(1, modeHeight)

        self.bins = bins
        self.axes = axes
        self.size = size
        
        self.countAxis = countAxis ?? defaultCountAxis(mode: modeHeight)
    }
    
    public init(data: D.Data, probabilities: [PValue]?, size: D.IntCoord, axes: D.Axes, countAxis: AxisNormalizer? = nil) {
        var bins = Array(repeating: Double(0), count: D.inlineArraySize(size:size))
        
        for i in 0..<D.count(data: data) {
            let point = D.value(in: data, at: i)
            let ndBin = D.pointToNDIndex(point: point, axes: axes, arraySize: size)
            let bin = D.inlineArrayIndex(ndIndex:ndBin, arraySize: size)
            bins[bin] += Double(probabilities?[i].p ?? 1)
        }
        
        self.init(bins:bins, size:size, axes:axes, countAxis:countAxis)
    }
    
  
}



fileprivate func defaultCountAxis(mode:Double?) -> AxisNormalizer {
    let upper = max(1, mode ?? 0)
    return .linear(minVal: 0, maxVal: upper)
}


public enum HistogramSmoothing:Codable, Equatable {
    case off, low, high
}
//
//public extension HistogramData<X> {
//    func convolute(kernel:Any?) -> HistogramData<X>? {
//        nil
//    }
//}
//public extension HistogramData<XY> {
//    func convolute(kernel:Any?) -> HistogramData<XY>? {
//        nil
//    }
//}

//func smooth()
//{
//    for i in 0..<size  {
//        for j in 0..<size  {
//            kernelSmooth(i,j)
//        }
//    }
//}


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
//    func bin(bin1d:Int) -> Tuple2<Int> {s
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


extension HistogramData<XY> {
    private func toImage(colormap:Colormap) -> Image? {
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
                let color = colormap.colorUInt8(at: Float(value))

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
    
    func toView(chartDef:ChartDef?) -> (any View)?
    {
        let view:(any View)? = {
            if chartDef?.contours ?? false {
                return ContoursView(bins: bins, size: size)      //width: size.x, height: size.y
//                    .scaleEffect(y: -1)
//                    .offset(y: 100)
            }
            
            return toImage(colormap: chartDef?.colormap ?? .jet)?.resizable()
        }()
        
        if let view {
            return view.scaleEffect(y: -1)
        }
        return nil
    }



    //------------------------------------------------------------------------
    struct MyShape: Shape {
        var path: Path
        
        func path(in rect: CGRect) -> Path {   path  }
    }
    
   
    struct ContoursView:  View {
        var bins: [Double]
        var size: D.IntCoord
        func getLineWidth(_ index: Int) -> CGFloat
        {
            return 1.0
            //index % 4 == 0 ? 0.5 : 0.8
            
        }
        func getColor(_ index: Int) -> Color
        {
            index % 4 == 0 ? Color.blue : Color.gray
        }
        
        var body: some View {

            GeometryReader { proxy in
                VStack {
                    let  viewSize = proxy.size
                    let sx = viewSize.width / 256           // TODO hardcoded
                    let sy = viewSize.height / 256
                    let contours = ContourBuilder(bins: bins, width: size.x, height: size.y)
                    let pathlist = contours.buildPathList()
                      
                    
                    ZStack {
                        ForEach(0..<pathlist.paths.count, id: \.self) { index in
                            MyShape(path: pathlist.paths[index])
                                .stroke(lineWidth: getLineWidth(index))
                                .foregroundColor(getColor(index))
                                .scaleEffect(x: sx,y:  sy, anchor: .topLeading)
                        }
                    }
                }
            }
        }
        
    }
//
//struct BadgeBackground: View {
//    var body: some View {
//        let path =  Path { path in
//            let width: CGFloat = 500.0
//            let height = width
//            path.move( to: CGPoint( x: width * 0.95, y: height * 0.20 ))
//            path.addLine( to: CGPoint( x: width * 0.15, y: height * 0.20 ))
//            path.addLine( to: CGPoint( x: width * 0.35, y: height * 0.80 ))
//            path.addLine( to: CGPoint( x: width * 0.95, y: height * 0.20 ))
//            
//            
//            
//            path.addLines(getContours1())
//        }.stroke(lineWidth: 3)
//            .fill(.blue)
//        return path
//    }

//}
}
