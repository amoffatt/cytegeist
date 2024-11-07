    //
    //  Gate.swift
    //  HousingData
    //
    //  Created by Adam Treister on 7/9/24.
    //

import Foundation
import SwiftUI
import CytegeistLibrary

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
//

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
    func xml() -> String
    /// self is a binding for the gate's view to be able to edit the gate itself through
//    func chartView(_ self:Binding<AnyGate?>, chart:ChartDef) -> ChartAnnotation?
//    func chartView(_ node:PopulationNode,
//                   chartSize:CGSize,
//                   chartDims:Tuple2<CDimension?>
//                   ) -> any View
    
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

public extension GateDef {
    func isEqualTo(_ other: (any GateDef)?) -> Bool {
        guard let otherGate = other as? Self else { return false }
        return self == otherGate
    }
}


public struct RangeGateDef : GateDef
{
    private var _min: ValueType
    private var _max: ValueType
//    private var _max: ValueType
    public var dims: [String]
    
    public var min: ValueType {
        get { _min }
        set { (_min, _max) = sort(newValue, _max) }
    }
    
    public var max: ValueType {
        get { _max }
        set { (_min, _max) = sort(_min, newValue) }
    }
    
    public init(_ dim:String, _ min: ValueType, _ max: ValueType)
    {
        (_min, _max) = sort(min, max)
        self.dims = [dim]
    }

    public func probability(of event:EventData) -> PValue
    {
        event.values[0] >= min && event.values[0] <= max ? .one : .zero
    }

    public func xml() -> String {
        return " "
    }
}

public struct RectGateDef : GateDef
{
    public var rect:CRect
    
//    public var minX: ValueType
//    public var maxX: ValueType
//    public var minY: ValueType
//    public var maxY: ValueType
    public var dims:[String]
//    public var rect: CGRect {
//        get {.init(from:min, to:max) }
//        set {
//            min = newValue.min
//            max = newValue.max
//        }
//    }

    public init(_ dims: Tuple2<String>, _ rect: CGRect)
    {
        self.rect = rect
        self.dims = dims.values
    }
    
    public init(_ dims: Tuple2<String>, _ minX: ValueType, _ maxX: ValueType, _ minY: ValueType, _ maxY: ValueType)
    {
        self.init(dims, CRect(from:.init(minX, minY), to:.init(maxX, maxY)))
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
        let point = CPoint(event.values[0], event.values[1])
        if rect.contains(point) {
            return .one
        }
        return .zero
//        if !(minX...maxX).contains(event.values[0]) {
//            return .zero
//        }
//        if !(minY...maxY).contains(event.values[1]) {
//            return .zero
//        }
    }
    public func xml() -> String {
        return " "
    }
//    public func chartView(_ node: PopulationNode, chartSize: CGSize, chartDims: Tuple2<CDimension?>) -> any View {
//            Text("Rect gate not yet supported")
//        guard let xAxis = chart.xAxis?.name, xAxis == dims.get(index:0),
//              let yAxis = chart.yAxis?.name, yAxis == dims.get(index:1)
//        else {
//            return nil
//        }
//        return .init(id:id) { sampleMeta, chartSize, editing in
//            if let xNormalizer = sampleMeta.parameter(named: xAxis)?.normalizer,
//               let yNormalizer = sampleMeta.parameter(named: yAxis)?.normalizer {
//                return RectGateView(gate: castBinding(self),
//                                    normalizers: .init(xNormalizer, yNormalizer),
//                                    chartSize: chartSize)
//            }
//            return EmptyView()
//        } remove: {}
        
//    }
}

public struct RadialGateDef : GateDef
{
    var centerX: CGFloat
    var centerY: CGFloat
    var radius: CGFloat
    public var dims:[String]
    
    public init(_ dims: Tuple2<String>, _ centerX: CGFloat, _ centerY: CGFloat, _ radius: CGFloat)
    {
        self.centerX = centerX
        self.centerY = centerY
        self.radius = radius
        self.dims = dims.values
    }
    
    public  static func == (lhs: RadialGateDef, rhs: RadialGateDef) -> Bool {
                return lhs.hashValue == rhs.hashValue
            }
    public func probability(of event:EventData) -> PValue
    {
        let pt = CGPoint(event.values[0], event.values[1])
        let center = CGPoint(centerX, centerY)
       return distance(pt, center) < radius
        ? PValue.one
        : PValue.zero
    }
    
    public init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    public func xml() -> String {
        return " "
    }
}

public protocol PathGate : GateDef {
    func normalizedPath() -> [CPoint]
}

public struct EllipsoidGateDef: PathGate {
    public var dims: [String]
    public var normalizedShape:Ellipsoid
    public var axes:Tuple2<AxisNormalizer>
    public init(_ dims: Tuple2<String>, _ normalizedShape:Ellipsoid, axes:Tuple2<AxisNormalizer>)
    {
        self.dims = dims.values
        self.normalizedShape = normalizedShape
        self.axes = axes
    }
    
    public func probability(of event: EventData) -> PValue {
        let normalizedPoint = CPoint(
            axes.x.normalize(event.values[0]),
            axes.y.normalize(event.values[1])
        )
        return normalizedShape.distanceSqr(of: normalizedPoint) <= 1 ? .one : .zero
    }
    
    public func normalizedPath() -> [CPoint] {
        normalizedShape
            .path(subdivisions:100)
//            .map { $0.unnormalize(axes) }
    }
    public func xml() -> String {
        return " "
    }}

public struct Ellipsoid: Codable, Hashable {
    public var center:CPoint
    public var major:ValueType = 0  // at angle 0, horizontal axis
    public var minor:ValueType = 0  // at angle 0, vertical axis
    public var angle:ValueType = 0
    
    public var majorVertices: [CPoint] {
        get {
            let dx = major * cos(angle)
            let dy = major * sin(angle)
            let vertex1 = CPoint(x: center.x + dx, y: center.y + dy)
            let vertex2 = CPoint(x: center.x - dx, y: center.y - dy)
            return [vertex1, vertex2]
        }
    }

    public var minorVertices: [CPoint] {
        get {
            let dx = minor * cos(angle + .pi / 2)
            let dy = minor * sin(angle + .pi / 2)
            let vertex1 = CPoint(x: center.x + dx, y: center.y + dy)
            let vertex2 = CPoint(x: center.x - dx, y: center.y - dy)
            return [vertex1, vertex2]
        }
    }
    
    public init(vertex0: CPoint, vertex1: CPoint, widthRatio: ValueType) {
        center = (vertex0 + vertex1) / 2
        let delta = vertex1 - vertex0
        major = delta.magnitude / 2
        minor = major * widthRatio
        angle = delta.angle
    }
    
    public init(center: CPoint, major: ValueType, minor: ValueType, angle: ValueType) {
        self.center = center
        self.major = major
        self.minor = minor
        self.angle = angle
    }
    
    public mutating func setMajor(relativeToCenter:CPoint) {
        let minorRatio = (minor / major).ifNotFinite(0.5)
        major = relativeToCenter.magnitude
        minor = minorRatio * major
        angle = relativeToCenter.angle
    }
    
    public mutating func setMinor(relativeToCenter:CPoint) {
        minor = relativeToCenter.magnitude
        angle = relativeToCenter.angle - .pi / 2
    }

    public func distanceSqr(of point:CPoint) -> ValueType {
        let transformed = (point - center).rotated(by: .radians(-angle))
        let distanceSqr = sqr(transformed.x / major) + sqr(transformed.y / minor)
        return distanceSqr
    }
    
    public func path(subdivisions: Int) -> [CPoint] {
        let angleIncrement = 2 * Double.pi / Double(subdivisions)
        
        return (0..<subdivisions).map { i in
            let theta = Double(i) * angleIncrement
            let p = CPoint(major * cos(theta), minor * sin(theta))
            
            let rotatedP = p.rotated(by: .radians(angle))
            
            return rotatedP + center
        }
    }
    public func xml() -> String {
        return " "
    }
//    public func scaled(_ scale:CGSize) -> Ellipsoid {
//        
//    }
}


public struct PolygonGateDef : GateDef {
    public var points : [CPoint] = []
    public var dims:[String]
    public init(_ dims:[String], points: [CPoint])
    {
        self.dims = dims
        self.points = points
    }
    public func probability(of: EventData) -> PValue {
        fatalError()
    }
    public func xml() -> String {
        return " "
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
