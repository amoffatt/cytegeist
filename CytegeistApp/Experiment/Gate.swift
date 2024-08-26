    //
    //  Gate.swift
    //  HousingData
    //
    //  Created by Adam Treister on 7/9/24.
    //

import Foundation
import SwiftUI
import CytegeistCore
import CytegeistLibrary

    //--------------------------------------------------------
class Gate : Codable, Hashable
{
    public var invert = false;         // any gate can be inverted
    var extraAttributes = AttributeStore()
    var spec: GateDef
    @CodableIgnored
    var color = Color.pink
    var opacity = 0.2
    
    init(spec: GateDef, color: Color, opacity: CGFloat)
    {
        self.spec = spec
        self.color = color
        self.opacity = opacity
    }
    
    
    init()
    {
        spec = GateDef()  // define empty
    }

        
   func setInvert(on: Bool)
    {
        self.invert = on
    }
    
    func hash(into hasher: inout Hasher) {
        ///        hasher.combine(x)
        ///         hasher.combine(y)
    }
    
    static func == (lhs: Gate, rhs: Gate) -> Bool {
        lhs.hashValue == rhs.hashValue;
    }
    
    public func testMembership(inNumber: Double) -> PValue
    {
        return PValue(1.0)
    }
    
        
    func createRequest() -> GateRequest {
        let p = spec.probability
        let probability:(EventData) -> PValue = invert
        ? { p($0).inverted }
        : { p($0) }
        
        return GateRequest(repr: "\(spec.hashValue)",
                    dimNames: spec.dims,
                    filter: probability
        )
    }

    
}

    //-----------------------------------------------------

class GateDef : Codable, Hashable, Equatable
{
    static func == (lhs: GateDef, rhs: GateDef) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    func hash(into hasher: inout Hasher) {
        for d in dims {
            hasher.combine(d)
        }
        hasher.combine(id)
    }
    
    var dims = [String]()
    var id = "-1"
    init (dims:[String] = [])
    {
        self.dims = dims
    }
    
    func probability(of:EventData) -> PValue {
        fatalError("Implemented")
    }
}

class BifurGateDef : GateDef
{
    var division: CGFloat
    
    init(_ division: CGFloat)
    {
        self.division = division
        super.init()
    }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}


class RangeGateDef : GateDef
{
    var min: ValueType
    var max: ValueType
    
    init(_ dim:String, _ min: ValueType, _ max: ValueType)
    {
        self.min = min
        self.max = max
        super.init(dims:[dim])
    }

    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override func hash(into hasher: inout Hasher) {
        super.hash(into: &hasher)
        hasher.combine(min)
        hasher.combine(max)
    }

    override func probability(of event:EventData) -> PValue
    {
            //  for d in dimensions where d.name?
        event.values[0] >= min && event.values[0] <= max
        ? PValue(1)
        : PValue(0)
        
    }
}

class RectGateDef : GateDef
{
    var minX: CGFloat
    var maxX: CGFloat
    var minY: CGFloat
    var maxY: CGFloat
    
    init(_ minX: CGFloat, _ maxX: CGFloat, _ minY: CGFloat, _ maxY: CGFloat)
    {
        self.minX = minX
        self.maxX = maxX
        self.minY = minY
        self.maxY = maxY
        super.init()
    }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

class RadialGateDef : GateDef
{
    var center: CGPoint
    var radius: CGFloat
    
    init (_ center: CGPoint, _ radius: CGFloat)
    {
        self.center = center
        self.radius = radius
        super.init()
    }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
}

class EllipsoidGateDef: GateDef
{
    var threshold = 1
    var sumDist = 0.0
    var foci: [CGPoint] = []
    var edges: [CGPoint] = []
    
    public func distance() -> Double
    {
        for _ in dims {
            sumDist += 2.0
        }
        return sumDist
    }
    init(foci:[CGPoint], edges: [CGPoint])
    {
        self.foci = foci
        self.edges = edges
        super.init()
    }
    init(_ a: CGPoint,_ b: CGPoint)
    {
        foci.append(a)
        foci.append(b)
        edges.append(a)
        edges.append(b)    // TODO ???
        
        super.init()
    }
    init(threshold: Int = 1) {
        super.init()    }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
}
    //    struct Point {
    //        var x = 0, y = 0
    //    }

class PolygonGateDef : GateDef
{
    var points : [CGPoint] = []
    init(points: [CGPoint])
    {
        super.init()
    }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

class SplineGateDef : PolygonGateDef
{
    
}
