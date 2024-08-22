//
//  Gate.swift
//  HousingData
//
//  Created by Adam Treister on 7/9/24.
//

import Foundation
import CytegeistLibrary

//--------------------------------------------------------
class Gate : Codable, Hashable
{
    public var invert = false;         // any gate can be inverted
    var extraAttributes = AttributeStore()
    var spec: GateDef
    
    
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
        true;
    }
    
    public func testMembership(inNumber: Double) -> PValue
    {
        return PValue(1.0)
    }
}

//-----------------------------------------------------

    class GateDef : Codable
    {
        var dims = [CDimension]()
        var invert: Bool
        var id = "-1"
        init ()
        {
            invert = false
        }
    }

    class BifurGate : GateDef
    {
        public func testMembership() -> Bool
        {
            //  for d in dimensions where d.name?
            
            invert ?  true : false
        }
     }
    

    class RectGate : GateDef
    {
        public func testMembership() -> Bool
        {
            //  for d in dimensions where d.name?
            
            invert ?  true : false
        }
    }
    
    class EllipsoidGate: GateDef
    {
        var threshold = 1
        var sumDist = 0.0
       
        public func distance() -> Double
        {
            for _ in dims {
                sumDist += 2.0
            }
            return sumDist
        }
        init(foci: [CGPoint], edge: [CGPoint])
        {
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

    class PolygonGate : GateDef
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

    class SplineGate : PolygonGate
    {
       
    }
