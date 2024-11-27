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


//------------------------------------------------------
//------------------------------------------------
struct CWindowPosition : Codable, Transferable
{
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: UTType.appleArchive)
    }

    var attributes = AttributeStore()
    var position = CGPoint(x: 0,y: 0)
    var size = CGSize(width: 0, height: 0)

    init(fjxml: TreeNode)
    {
        attributes.dictionary.merge(fjxml.attrib.dictionary, uniquingKeysWith: +)
        let  w = Double(fjxml.attrib.dictionary["width"] ?? "0.0")
        let h = Double(fjxml.attrib.dictionary["height"] ?? "0.0")
        size = CGSize(width: w!, height: h!)
        let xx = Double(fjxml.attrib.dictionary["x"] ?? "0.0")
        let yy = Double(fjxml.attrib.dictionary["height"] ?? "0.0")
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

      var attributes = AttributeStore()
      init(fjxml: TreeNode)
      {
          attributes.dictionary.merge(fjxml.attrib.dictionary, uniquingKeysWith: +)
      }
  }



//    ---------------------------------------------------------------------
//     MISC JUNK that might be streamed in from a FJ workspace
//
//struct TableSchema : Codable
//{
//    var tableName = "a table"
//    
//        //    var columns : [TableColumn]
//    init(_ xml: TreeNode)
//    {
//    }
//}
//
//struct LayoutSchema : Codable
//{
//    var layoutName = "a layout"
//    
//        //    var columns : [TableColumn]
//    init(_ xml: TreeNode)
//    {
//    }
//}

    struct PageSection
    {
      var  sectionName = "header"
        var content = ""
    }
    struct PrintReport
    {
        var scale = 1.0
        var header : PageSection
        var footer : PageSection
    }
    struct BatchInfo  : Codable, Hashable
    {
        var  iter = ["", ""]
        var  discrim = ["", ""]
        var  destination = "JPEG"
    }
