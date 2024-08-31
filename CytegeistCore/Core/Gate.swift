    //
    //  Gate.swift
    //  HousingData
    //
    //  Created by Adam Treister on 7/9/24.
    //

import Foundation
import SwiftUI
import CytegeistLibrary
import Combine

    //--------------------------------------------------------
//public struct Gate : Codable, Hashable
//{
//    
//    public var invert = false;         // any gate can be inverted
////    var extraAttributes = AttributeStore()
//    public var spec: (any GateDef)?
//    @CodableIgnored
//    public var color = Color.pink
//    public var opacity = 0.2
//    
//    public init(spec: any GateDef, color: Color, opacity: CGFloat)
//    {
//        self.spec = spec
//        self.color = color
//        self.opacity = opacity
//    }
//    
//    
//    public init()
//    {
////        spec = GateDef()  // define empty
//    }
//
//        
////   public func setInvert(on: Bool)
////    {
////        self.invert = on
////    }
//    public init(from decoder: any Decoder) throws {
//        fatalError()
//    }
//    
//    public func encode(to encoder: any Encoder) throws {
////        color.encode(to: encoder)
//        try opacity.encode(to: encoder)
//        try spec?.encode(to: encoder)
//    }
//    
//    
//    public func hash(into hasher: inout Hasher) {
//        ///        hasher.combine(x)
//        ///         hasher.combine(y)
//    }
//    
//    public static func == (lhs: Gate, rhs: Gate) -> Bool {
//        lhs.hashValue == rhs.hashValue;
//    }
//    
////    public func testMembership(inNumber: Double) -> PValue
////    {
////        return PValue(1.0)
////    }
//    
//        
////    func createRequest() -> (any GateDef)? {
////        return spec
////        guard let spec else {
////            return nil
////        }
//        
////        let p = spec.probability
////        let probability:(EventData) -> PValue = invert
////        ? { p($0).inverted }
////        : { p($0) }
////        
////        return GateRequest(repr: "\(spec.hashValue)",
////                    dimNames: spec.dims,
////                    filter: probability
////        )
////    }
//
//}

    //-----------------------------------------------------

public typealias AnyGate = (any GateDef)

public protocol GateDef : Codable, Hashable, Equatable
{
//    static func == (lhs: GateDef, rhs: GateDef) -> Bool {
//        return lhs.hashValue == rhs.hashValue
//    }
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(dims)
//        hasher.combine(id)
//    }
    
    var dims:[String] { get }
//    var id = "-1"
//    init (dims:[String] = [])
//    {
//        self.dims = dims
//    }
    
    func probability(of:EventData) -> PValue
//        fatalError("Implemented")
//    }
    
    /// self is a binding for the gate's view to be able to edit the gate itself through
    func chartView(_ self:Binding<AnyGate?>, id:String, chart:ChartDef) -> ChartAnnotation?
}

public extension GateDef {
    func isEqualTo(_ other: (any GateDef)?) -> Bool {
        guard let otherGate = other as? Self else { return false }
        return self == otherGate
    }
}

//class BifurGateDef : GateDef
//{
//    var division: CGFloat
//    var dims:[String]
//    
//    init(_ division: CGFloat)
//    {
//        self.division = division
//        super.init()
//    }
//    
//    init(from decoder: any Decoder) throws {
//        fatalError("init(from:) has not been implemented")
//    }
//}


public struct RangeGateDef : GateDef
{
    
    public var min: ValueType
    public var max: ValueType
    public var dims: [String]
    
    public init(_ dim:String, _ min: ValueType, _ max: ValueType)
    {
        self.min = min
        self.max = max
        self.dims = [dim]
    }

//    init(from decoder: any Decoder) throws {
//        fatalError("init(from:) has not been implemented")
//    }
//    
//    func hash(into hasher: inout Hasher) {
//        hasher.combineMany(min, max, dims)
//    }

    public func probability(of event:EventData) -> PValue
    {
            //  for d in dimensions where d.name?
        event.values[0] >= min && event.values[0] <= max
        ? PValue(1)
        : PValue(0)
    }
    
    public func chartView(_ self:Binding<AnyGate?>, id:String, chart: ChartDef) -> ChartAnnotation? {
        guard let xAxis = chart.xAxis?.name,
              xAxis == dims.first else {
            return nil
        }
        
        return .init(id:id) { sampleMeta, chartSize, editing in
                if let xNormalizer = sampleMeta.parameter(named: xAxis)?.normalizer {
                    return RangeGateView(
                        gate: castBinding(self),
                        normalizer: xNormalizer,
                        chartSize: chartSize,
                        editing: editing)
                }
                return EmptyView()
        }
        
    }
}

public struct RectGateDef : GateDef
{

    
    public var minX: ValueType
    public var maxX: ValueType
    public var minY: ValueType
    public var maxY: ValueType
    public var dims:[String]
    
    public var min: CGPoint { .init(x:minX, y:minY) }
    public var max: CGPoint { .init(x:maxX, y:maxY) }
    public var rect: CGRect { .init(from:min, to:max) }

    public init(_ dims: Tuple2<String>, _ rect: CGRect)
    {
        self.init(dims, rect.minX, rect.maxX, rect.minY, rect.maxY)
    }
    
    public init(_ dims: Tuple2<String>, _ minX: ValueType, _ maxX: ValueType, _ minY: ValueType, _ maxY: ValueType)
    {
        self.minX = minX
        self.maxX = maxX
        self.minY = minY
        self.maxY = maxY
        self.dims = dims.values
    }
    
    public init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
//    override func hash(into hasher: inout Hasher) {
//        super.hash(into: &hasher)
//        hasher.combineMany(minX, maxX, minY, maxY)
//    }
    
    public func probability(of event:EventData) -> PValue
    {
            //  for d in dimensions where d.name?
        if !(minX...maxX).contains(event.values[0]) {
            return .zero
        }
        if !(minY...maxY).contains(event.values[1]) {
            return .zero
        }
        return .one
    }
    
    public func chartView(_ self:Binding<AnyGate?>, id:String, chart: ChartDef) -> ChartAnnotation? {
        
        guard let xAxis = chart.xAxis?.name, xAxis == dims.get(index:0),
              let yAxis = chart.yAxis?.name, yAxis == dims.get(index:1)
        else {
            return nil
        }
        return .init(id:id) { sampleMeta, chartSize, editing in
            if let xNormalizer = sampleMeta.parameter(named: xAxis)?.normalizer,
               let yNormalizer = sampleMeta.parameter(named: yAxis)?.normalizer {
                return RectGateView(gate: castBinding(self),
                                    normalizers: .init(xNormalizer, yNormalizer),
                                    chartSize: chartSize)
            }
            return EmptyView()
        }
        
    }
}

//public class RadialGateDef : GateDef
//{
//    var center: CGPoint
//    var radius: CGFloat
//    
//    init (_ center: CGPoint, _ radius: CGFloat)
//    {
//        self.center = center
//        self.radius = radius
//        super.init()
//    }
//    
//    required init(from decoder: any Decoder) throws {
//        fatalError("init(from:) has not been implemented")
//    }
//    
//}

//public class EllipsoidGateDef: GateDef
//{
//    var threshold = 1
//    var sumDist = 0.0
//    var foci: [CGPoint] = []
//    var edges: [CGPoint] = []
//    
//    public func distance() -> Double
//    {
//        for _ in dims {
//            sumDist += 2.0
//        }
//        return sumDist
//    }
//    init(foci:[CGPoint], edges: [CGPoint])
//    {
//        self.foci = foci
//        self.edges = edges
//        super.init()
//    }
//    init(_ a: CGPoint,_ b: CGPoint)
//    {
//        foci.append(a)
//        foci.append(b)
//        edges.append(a)
//        edges.append(b)    // TODO ???
//        
//        super.init()
//    }
//    init(threshold: Int = 1) {
//        super.init()    }
//    
//    required init(from decoder: any Decoder) throws {
//        fatalError("init(from:) has not been implemented")
//    }
//    
//}
    //    struct Point {
    //        var x = 0, y = 0
    //    }

public struct CPoint : Equatable, Hashable {
    var x:ValueType, y:ValueType
}

public struct PolygonGateDef : Hashable
{
    func probability(of: EventData) -> PValue {
        fatalError()
    }
    
    var points : [CPoint] = []
    var dims:[String]
    init(_ dims:[String], points: [CPoint])
    {
        self.dims = dims
        self.points = points
    }
    
    init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

//public class SplineGateDef : GateDef
//{
//    func probability(of: EventData) -> PValue {
//        fatalError()
//    }
//    
//    var points : [CPoint] = []
//    var dims:[String]
//}
