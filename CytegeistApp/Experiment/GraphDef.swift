//
//  Graph.swift
//  filereader
//
//  Created by Adam Treister on 7/24/24.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import CytegeistLibrary

enum XYZ : Codable, Transferable {    case x, y, z, na
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: UTType.appleArchive)
    }
}

func readDim(_ dim: String?) -> XYZ
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
//------------------------------------------------------ 
struct GraphDef : Codable, Transferable
{
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: UTType.appleArchive)
    }
    var attributes = [String : String]()
    var axes =  [XYZ : AxisDef ]()
    var textTraits = [TextTraits]()
    
    init()
    {
        
        
    }
    init(_ xml: TreeNode)
    {
        assert(xml.value == "Graph")
        attributes.merge(xml.attrib, uniquingKeysWith: +)
        if let wp = xml.findChild(value: "Axis")
        {
            let dim = readDim(wp.attrib["dimension"])
            let name = wp.attrib["name"] ?? ""
            let label = wp.attrib["label"] ?? ""
            let auto = wp.attrib["auto"] != "0"
            axes[dim] = AxisDef(name: name , label: label, auto: auto)
        }
            
        if let settings = xml.findChild(value: "GraphSettings")
        {
            attributes.merge(settings.attrib, uniquingKeysWith: +)
        }
        if let env = xml.findChild(value: "GraphEnvironment")
        {
            attributes.merge(env.attrib, uniquingKeysWith: +)
            for  ttraits in env.children where ttraits.value == "TextTraits" {
                textTraits.append(TextTraits(ttraits))
            }
        }
    }
 }
//------------------------------------------------
struct AxisDef : Codable, Transferable
{
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: UTType.appleArchive)
    }

    var attributes = [String : String]()
    var name = ""
    var label = ""
    var auto = true

    init(name: String, label: String, auto: Bool)
    {
        self.name = name
        self.label = label
        self.auto = auto

    }
    init(xml: TreeNode)
    {
        attributes.merge(xml.attrib, uniquingKeysWith: +)
        self.name = attributes[name] ?? ""
        self.label = attributes[label] ??  ""
        self.auto = (attributes["auto"] ??  "") != "0"
    }

}
//------------------------------------------------
struct CWindowPosition : Codable, Transferable
{
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: UTType.appleArchive)
    }

    var attributes = [String : String]()
    var position = CGPoint(x: 0,y: 0)
    var size = CGSize(width: 0, height: 0)

    init(xml: TreeNode)
    {
        attributes.merge(xml.attrib, uniquingKeysWith: +)
        let  w = Double(xml.attrib["width"] ?? "0.0")
        let h = Double(xml.attrib["height"] ?? "0.0")
        size = CGSize(width: w!, height: h!)
        let xx = Double(xml.attrib["x"] ?? "0.0")
        let yy = Double(xml.attrib["height"] ?? "0.0")
        position = CGPoint(x: xx!, y: yy!)
      }

}
//------------------------------------------------
// not sure if these are necessary in cytegeist.  We grab them for now
  struct TextTraits  : Codable, Transferable
{
      static var transferRepresentation: some TransferRepresentation {
          CodableRepresentation(contentType: UTType.appleArchive)
      }

      var attributes = [String : String]()
      init(_ xml: TreeNode)
      {
          attributes.merge(xml.attrib, uniquingKeysWith: +)
      }
  }
