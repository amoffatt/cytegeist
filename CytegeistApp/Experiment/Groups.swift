//
//  Groups.swift
//  CytegeistApp
//
//  Created by Adam Treister on 11/3/24.
//

import Foundation
import CytegeistLibrary
import CytegeistCore
import SwiftUI
import Combine

// Questionable if these should be different classes
    //--------------------------------------------------------------------------------
    //Model
public struct CGroup : Identifiable, Codable
{
    public var id = UUID()
    var name = ""
    var keyword: String?
    var value: String?
    @CodableIgnored
    var color: Color?
    
    init(name: String = "name", color: Color?, keyword: String?, value:  String?) {
        self.name = name
        self.color = color
        self.keyword = keyword
        self.value = value
    }
    
    public func xml() -> String {
        return "<Group " + attributes() + "/>"
    }
    
    public func attributes() -> String {
        return "name=\(self.name) keyword=\(self.keyword ?? "") "
//  keyword=\(self.keyword)      + "value=" + self.value + " "
//        + "color=" + self.color?.description + " "
    }
    init(xml: TreeNode) {
        let attr = xml.attrib.dictionary
        self.name = attr["name"] ?? ""
        self.color = (attr["color"]  ?? "blue").toColor()
        self.keyword = attr["keyword"] ?? ""
        self.value = attr["value"] ?? ""

    }
    
}
    //--------------------------------------------------------------------------------
    //Model
struct CPanel : Usable
{
    var id = UUID()
    var name = ""
    var keyword: String?
    var values: String?         // should be [String]???
    @CodableIgnored
    var color: Color?
    
    public static func == (lhs: CPanel, rhs: CPanel) -> Bool {   lhs.id == rhs.id   }
    
    init(name: String = "name", color: Color?, keyword: String?, values:  String?) {
        self.name = name
        self.color = color
        self.keyword = keyword
        self.values = ""
    }
    public func xml() -> String {
        return "<Panel " + attributes() + "/>"
    }
    
    public func attributes() -> String {
        return "name=\(self.name) keyword=\(self.keyword ?? "") "
            //        + "values=" + self.values + " "
            //        + "color=" + self.color?.description + " "
    }
    
    init(_ xml: TreeNode) {
        let attr = xml.attrib.dictionary
        self.name = attr["name"] ?? ""
        self.name = attr["color"] ?? ""
        self.keyword = attr["keyword"] ?? ""
        self.values = attr["values"] ?? ""
    }
}
