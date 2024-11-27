//
//  ChartDefs.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 8/22/24.
//

import Foundation
import CytegeistLibrary

public enum ChartColormap: Hashable, Codable {
    case jet
    case zebra
    
    var colormap:Colormap {
        switch self {
            case .jet: return .jet
            case .zebra: return .zebra(levels: 10)
        }
    }
}

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
    public var colorAxis: AxisDef? = nil
    public var sizeAxis: AxisDef? = nil
    
    public var smoothing:HistogramSmoothing = .low
    public var contours:Bool = false
    public var showOutliers:Bool = false
    
    /// Used by 3D chart
    public var maxPointCount:Int?
    
    public var colormap:ChartColormap = .jet

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

}

