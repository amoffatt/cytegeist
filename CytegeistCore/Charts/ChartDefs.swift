//
//  ChartDefs.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 8/22/24.
//

import Foundation
import CytegeistLibrary

public struct ChartDef : Hashable, Codable//, Transferable
{
//    static var transferRepresentation: some TransferRepresentation {
//        CodableRepresentation(contentType: UTType.appleArchive)
//    }
    public var extraAttributes = AttributeStore()
    
    public var name: String = ""
    public var label: String = ""
    
    public var xAxis: AxisDef? = nil
    public var yAxis: AxisDef? = nil
    public var zAxis: AxisDef? = nil
    
    public init()
    {
        
        
    }
 }
//------------------------------------------------
public struct AxisDef : Hashable, Codable//, Transferable
{
//    static var transferRepresentation: some TransferRepresentation {
//        CodableRepresentation(contentType: UTType.appleArchive)
//    }

    var extraAttributes = AttributeStore()
    
    public var name:String
    public var label:String
    public var auto:Bool

    public init(name: String = "", label: String = "", auto: Bool = true)
    {
        self.name = name
        self.label = label
        self.auto = auto
    }

}
