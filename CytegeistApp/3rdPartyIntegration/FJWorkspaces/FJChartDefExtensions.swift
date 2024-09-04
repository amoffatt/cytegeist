//
//  Graph.swift
//  filereader
//
//  Created by Adam Treister on 7/24/24.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import CytegeistCore
import CytegeistLibrary

enum XYZ : Codable, Transferable {    case x, y, z, na
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: UTType.appleArchive)
    }
}

//
//extension ChartDef {
////    static var transferRepresentation: some TransferRepresentation {
////        CodableRepresentation(contentType: UTType.appleArchive)
////    }
////    var attributes = [String : String]()
////    var textTraits = [TextTraits]()
//    
//    init(fjxml: TreeNode)
//    {
//        self.init()
//        
//        assert(fjxml.value == "Graph")
//        extraAttributes.merge(fjxml.attrib, uniquingKeysWith: +)
//        
//        for axisXml in fjxml.findChildren(value: "Axis")
//        {
//            let axis = AxisDef(fjxml: axisXml)
//            switch AxisDef.readDim(axisXml.attrib["dimension"]) {
//            case .x: self.xAxis = axis
//            case .y: self.yAxis = axis
//            case .z: self.zAxis = axis
//            default: break
//            }
//        }
//            
//        if let settings = fjxml.findChild(value: "GraphSettings")
//        {
//            extraAttributes.merge(settings.attrib, uniquingKeysWith: +)
//        }
//        if let env = fjxml.findChild(value: "GraphEnvironment")
//        {
//            extraAttributes.merge(env.attrib, uniquingKeysWith: +)
////            for  ttraits in env.children where ttraits.value == "TextTraits" {
////                textTraits.append(TextTraits(ttraits))
////            }
//        }
//    }
// }
//
//extension AxisDef {//:  Transferable {
//    static func readDim(_ dim: String?) -> XYZ
//    {
//        switch dim
//        {
//            case "x":  return XYZ.x
//            case "y":  return XYZ.y
//            case "z":  return XYZ.z
//            default: print("error")
//                        return XYZ.na
//        }
//    }
////    static var transferRepresentation: some TransferRepresentation {
////        CodableRepresentation(contentType: UTType.appleArchive)
////    }
//
//    init(fjxml: TreeNode)
//    {
//        self.init()
////        attributes.merge(xml.attrib, uniquingKeysWith: +)
//        self.name = fjxml.attrib["name"] ?? ""
//        self.label = fjxml.attrib["label"] ??  ""
//        self.auto = (fjxml.attrib["auto"] ??  "") != "0"
//    }
//
//}


//------------------------------------------------------
//------------------------------------------------
//struct CWindowPosition : Codable, Transferable
//{
//    static var transferRepresentation: some TransferRepresentation {
//        CodableRepresentation(contentType: UTType.appleArchive)
//    }
//
//    var attributes = [String : String]()
//    var position = CGPoint(x: 0,y: 0)
//    var size = CGSize(width: 0, height: 0)
//
//    init(fjxml: TreeNode)
//    {
//        attributes.merge(fjxml.attrib, uniquingKeysWith: +)
//        let  w = Double(fjxml.attrib["width"] ?? "0.0")
//        let h = Double(fjxml.attrib["height"] ?? "0.0")
//        size = CGSize(width: w!, height: h!)
//        let xx = Double(fjxml.attrib["x"] ?? "0.0")
//        let yy = Double(fjxml.attrib["height"] ?? "0.0")
//        position = CGPoint(x: xx!, y: yy!)
//      }
//
//}
//------------------------------------------------
// not sure if these are necessary in cytegeist.  We grab them for now
//  struct TextTraits  : Codable, Transferable
//{
//      static var transferRepresentation: some TransferRepresentation {
//          CodableRepresentation(contentType: UTType.appleArchive)
//      }
//
//      var attributes = [String : String]()
//      init(fjxml: TreeNode)
//      {
//          attributes.merge(fjxml.attrib, uniquingKeysWith: +)
//      }
//  }
//


    //---------------------------------------------------------------------
    // MISC JUNK that might be streamed in from a FJ workspace
    //
    //struct TableSchema : Codable
    //{
    //    var tableName = "a table"
    //
    //   //    var columns : [TableColumn]
    //    init(_ xml: TreeNode)
    //    {
    //    }
    //}
    //
    //struct PageSection
    //{
    //  var  sectionName = "header"
    //    var content = ""
    //}
    //struct PrintReport
    //{
    //    var scale = 1.0
    //    var header : PageSection
    //    var footer : PageSection
    //}
    //struct BatchInfo  : Codable, Hashable
    //{
    //    var  iter = ["", ""]
    //    var  discrim = ["", ""]
    //    var  destination = "JPEG"
    //}
