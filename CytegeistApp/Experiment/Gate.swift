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
    var attributes = [String : String]()
    var spec: GateDef
    
    
    init()
    {
        spec = GateDef()  // define empty
    }
    
    init(xml: TreeNode)
    {
        attributes.merge(xml.attrib, uniquingKeysWith: +)
        spec = GateDef()  // define empty
        
        for node in xml.children
        {
            spec.dims += readDimensions(xml: node)
             switch node.value {
                
            case "gating:PolygonGate":
                let pts: [CGPoint] = readVertices(xml: node)
                spec  = PolygonGate(points: pts)

            case "gating:RectangleGate":
                print ("rect gate switch")
                spec  = RectGate()

            case "gating:EllipsoidGate":
                let foci = readVertices(xml: node)
                let edges = readEdges(xml: node.findChild(value: "gating:edge") ?? node)
                spec  = EllipsoidGate(foci: foci, edge: edges)
                
            default: print ("in default of gate switch")
            }
            
        }
    }
                                 
    func readDimensions(xml: TreeNode) -> [CDimension]
    {
        var dims = [CDimension]()
        for dim in xml.children where (dim.value == "gating:dimension")
         {
            let dim2 = dim.children.first
            assert(dim2!.value == "data-type:fcs-dimension")
            let dimName = dim2!.attrib["data-type:name"]!
            if !dimName.isEmpty {
                dims.append(CDimension(name: dimName))
            }
      }
        return dims
    }
        
    func readVertices(xml: TreeNode) -> [CGPoint]
    {
        var pts = [CGPoint]()
        for pt in xml.children where (pt.value == "gating:vertex")
        {
            if let p = readValueFromVertex(xml: pt)
            {
                pts.append(p)
            }
        }
        return pts
    }
        
    func readEdges(xml: TreeNode) -> [CGPoint]
    {
        var pts = [CGPoint]()
        for pt in xml.children where (pt.value == "gating:vertex")  {
            pts.append (readValueFromVertex(xml: pt) ?? CGPoint.zero)       // NO dont add extra zeros!
        }
    return pts
    }

    func readValueFromVertex(xml: TreeNode) -> CGPoint?
    {
        assert(xml.value == "gating:vertex")
        //     assert(2 children of type gating:coordinate
        let key = xml.children[0].attrib["data-type:value"]
        let v1 = Double(key!)
        let key2 = xml.children[1].attrib["data-type:value"]
        let v2 = Double(key2!)
        return CGPoint(x: v1!,y: v2!)
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
        init(xml: TreeNode)
        {
            invert = false
        }
    //    typealias GateDef .empty
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
