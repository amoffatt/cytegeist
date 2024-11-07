//
//  ChartDefs.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 8/22/24.
//

import Foundation
import CytegeistLibrary

public struct ChartDef : Hashable, Codable, Equatable//, Transferable
{
    public static func == (lhs: ChartDef, rhs: ChartDef) -> Bool {
        if lhs.name != rhs.name { return false }
        if lhs.xAxis != rhs.xAxis { return false }
        if lhs.yAxis != rhs.yAxis { return false }
        return true
    }
    
//    static var transferRepresentation: some TransferRepresentation {
//        CodableRepresentation(contentType: UTType.appleArchive)
//    }
//    public var extraAttributes = AttributeStore()
    
    public var name: String = ""
    public var label: String = ""
    public var extraAttributes: AttributeStore? = nil    //optional
    public var xAxis: AxisDef? = nil
    public var yAxis: AxisDef? = nil
    public var zAxis: AxisDef? = nil
    public var colorAxis: AxisDef? = nil
    public var sizeAxis: AxisDef? = nil
    
    public var smoothing:HistogramSmoothing = .low
    public var contours:Bool = false
    public var showOutliers:Bool = false
    
    public var colormap:Colormap? { .jet }
    
    public init()
    {
        
        
    }
    public func xml() -> String {
        let head = "<Graph " + attributes() + ">\n"
        let axes = (xAxis?.xml() ?? "") + (yAxis?.xml() ?? "")// + (zAxis?.xml() ?? "")
        let settings = "<GraphSettings contours=\(self.contours ? "true" : "false")/>"
        let env = "<GraphEnvironment> <TextTraits /> </GraphEnvironment>\n"
        return head + axes + settings + env + "</Graph>\n"
    }
    
    public func attributes() -> String {
        return "name= \(self.name) "
    }
    
    public init(fjxml: TreeNode)
    {
        self.init()
        
        assert(fjxml.value == "Graph")
        extraAttributes?.dictionary.merge(fjxml.attrib.dictionary, uniquingKeysWith: +)
        
        for axisXml in fjxml.findChildren(value: "Axis")
        {
            let axis = AxisDef(fjxml: axisXml)
            switch AxisDef.readDim(axisXml.attrib.dictionary["dimension"]) {
                case .x: self.xAxis = axis
                case .y: self.yAxis = axis
                case .z: self.zAxis = axis
                default: break
            }
        }
        
        if let settings = fjxml.findChild(value: "GraphSettings")
        {
            extraAttributes?.dictionary.merge(settings.attrib.dictionary, uniquingKeysWith: +)
        }
        if let env = fjxml.findChild(value: "GraphEnvironment")
        {
            extraAttributes?.dictionary.merge(env.attrib.dictionary, uniquingKeysWith: +)
                //            for  ttraits in env.children where ttraits.value == "TextTraits" {
                //                textTraits.append(TextTraits(ttraits))
                //            }
        }
    }
}

//------------------------------------------------

enum XYZ : Codable {    case x, y, z, na
        //    static var transferRepresentation: some TransferRepresentation {
        //        CodableRepresentation(contentType: UTType.appleArchive)
        //    }
    public func xml() -> String {
        switch self {
            case .x: return "x"
            case .y: return "y"
            case .z: return "z"
            case .na: return "na"
        }
    }
    
}

//------------------------------------------------
public struct AxisDef : Hashable, Codable, Equatable//, Transferable
{
//    static var transferRepresentation: some TransferRepresentation {
//        CodableRepresentation(contentType: UTType.appleArchive)
//    }

//    var extraAttributes = AttributeStore()
    
    public var dim:String
    public var customLabel:String
    public var auto:Bool
    public var showTicks:Bool
    public var showTickLabels:Bool
    public var showLabel:Bool
    public var scale:CGFloat?

    public init(dim: String = "", label: String = "", auto: Bool = true, showTicks: Bool = true, showTickLabels: Bool = true, showLabel: Bool = true, scale: CGFloat? = nil)
    {
        self.dim = dim
        self.customLabel = label
        self.auto = auto
        self.showTicks = showTicks
        self.showTickLabels = showTickLabels
        self.showLabel = showLabel
        self.scale = scale
    }
    static func readDim(_ dim: String?) -> XYZ
    {
        switch dim
        {
            case "x":  return XYZ.x
            case "y":  return XYZ.y
            case "z":  return XYZ.z
            default: print("error")
                return XYZ.na
        }
    }
        //    static var transferRepresentation: some TransferRepresentation {
        //        CodableRepresentation(contentType: UTType.appleArchive)
        //    }
    
    public static func == (lhs: AxisDef, rhs: AxisDef) -> Bool {
        if lhs.dim != rhs.dim { return false }
        if lhs.auto != rhs.auto { return false }
        return true
    }
    
    public func xml() -> String {
        return "<Axis " + attributes() + "/> \n"
    }
    public func attributes() -> String {
       return " dimension=\(self.dim) name=\(self.customLabel) label=\(self.customLabel) auto=\(self.auto) "
    }

    init(fjxml: TreeNode)
    {
        self.init()
            //        attributes.merge(xml.attrib, uniquingKeysWith: +)
        self.dim = fjxml.attrib.dictionary["name"] ?? ""
        self.customLabel = fjxml.attrib.dictionary["label"] ??  ""
        self.auto = (fjxml.attrib.dictionary["auto"] ??  "") != "0"
    }
}

