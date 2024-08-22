//
//  FJGatingExtensions.swift
//  CytegeistApp
//
//  Created by Aaron Moffatt on 8/22/24.
//

import Foundation
import CytegeistLibrary
import CytegeistCore

extension Gate {
    
    convenience init(fjxml: TreeNode)
    {
        self.init()
        extraAttributes.merge(fjxml.attrib, uniquingKeysWith: +)
        
        for node in fjxml.children
        {
            spec.dims += readDimensions(fjxml: node)
            switch node.value {
                
            case "gating:PolygonGate":
                let pts: [CGPoint] = readVertices(fjxml: node)
                spec  = PolygonGate(points: pts)
                
            case "gating:RectangleGate":
                print ("rect gate switch")
                spec  = RectGate()
                
            case "gating:EllipsoidGate":
                let foci = readVertices(fjxml: node)
                let edges = readEdges(fjxml: node.findChild(value: "gating:edge") ?? node)
                spec  = EllipsoidGate(foci: foci, edge: edges)
                
            default: print ("in default of gate switch")
            }
            
        }
    }
    
    func readDimensions(fjxml: TreeNode) -> [CDimension]
    {
        var dims = [CDimension]()
        for dim in fjxml.children where (dim.value == "gating:dimension")
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
    
    func readVertices(fjxml: TreeNode) -> [CGPoint]
    {
        var pts = [CGPoint]()
        for pt in fjxml.children where (pt.value == "gating:vertex")
        {
            if let p = readValueFromVertex(fjxml: pt)
            {
                pts.append(p)
            }
        }
        return pts
    }
    
    func readEdges(fjxml: TreeNode) -> [CGPoint]
    {
        var pts = [CGPoint]()
        for pt in fjxml.children where (pt.value == "gating:vertex")  {
            pts.append (readValueFromVertex(fjxml: pt) ?? CGPoint.zero)       // NO dont add extra zeros!
        }
        return pts
    }
    
    func readValueFromVertex(fjxml: TreeNode) -> CGPoint?
    {
        assert(fjxml.value == "gating:vertex")
        //     assert(2 children of type gating:coordinate
        let key = fjxml.children[0].attrib["data-type:value"]
        let v1 = Double(key!)
        let key2 = fjxml.children[1].attrib["data-type:value"]
        let v2 = Double(key2!)
        return CGPoint(x: v1!,y: v2!)
    }
}
