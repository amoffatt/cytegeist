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
//    static var transferRepresentation: some TransferRepresentation {
//        CodableRepresentation(contentType: UTType.appleArchive)
//    }
//    public var extraAttributes = AttributeStore()
    
    public var name: String = ""
    public var label: String = ""
    
    public var xAxis: AxisDef? = nil
    public var yAxis: AxisDef? = nil
    public var zAxis: AxisDef? = nil
    
    public var smoothing:HistogramSmoothing = .low
    public var contours:Bool = false
    public var showOutliers:Bool = false
    
    public var colormap:Colormap? { .jet }

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

//    var extraAttributes = AttributeStore()
    
    public var name:String
    public var label:String
    public var auto:Bool

    public init(dim: String = "", label: String = "", auto: Bool = true)
    {
        self.name = dim
        self.label = label.isEmpty ? dim : label
        self.auto = auto
    }

}

