//
//  AnalysisNode.swift
//
//  Created by Adam Treister on 7/25/24.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers.UTType
import CytegeistLibrary

public extension UTType {  static var population = UTType(exportedAs: "cytegeist.population")   }
enum AnalysisNodeError : Error {  case noSampleRef      }
//---------------------------------------------------------
@Observable
public class AnalysisNode : Codable, Transferable, Identifiable, Hashable, CustomStringConvertible
{
    
    public var id = UUID()
    public var name: String = ""
    public var description: String = ""
    public var sample: Sample? = nil                      // nil except at the root node
    public var graphDef = ChartDef()              // how this population wants to be shown
    public var statistics =  [String : Double]()         // cache of stats with values
    public private(set) var children: [AnalysisNode] = []        // subpopulations dependent on us
    private var _parent: AnalysisNode?
    public var parent: AnalysisNode? {
        get { _parent }
        set {
            if newValue == parent {  return }
            if let _parent {    _parent._removeChild(self)   }
            _parent = newValue
            if let _parent {    _parent._addChild(self)     }
        }
    }
        //  these fields are only applicable to populations
    @ObservationIgnored
    @CodableIgnored
    public var gate: AnyGate? = nil                      // the predicate to filter ones parent
//    @ObservationIgnored
//    @CodableIgnored
//    public var parentImage: NSImage? = nil            // a picture of parent pop showing our gate
    @ObservationIgnored
    @CodableIgnored
    public var color: Color? = nil
    public var opacity: Double = 1.0
    public var labelOffset: CGPoint = .zero
    public var invert: Bool = false
//    public var isExpanded: Bool = true
    
    
        //--------------------------------------------------------
    public static func == (lhs: AnalysisNode, rhs: AnalysisNode) -> Bool {   lhs.id == rhs.id  }
    public func hash(into hasher: inout Hasher) {        hasher.combine(id)    }
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: UTType.population)
    }
        //--------------------------------------------------------
    public init() {    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decode(UUID.self, forKey: ._id)
        self._name = try container.decode(String.self, forKey: ._name)
        self._sample = try container.decodeIfPresent(Sample.self, forKey: ._sample)
        self._graphDef = try container.decode(ChartDef.self, forKey: ._graphDef)
        self._statistics = try container.decode([String : Double].self, forKey: ._statistics)
        self._children = try container.decode([AnalysisNode].self, forKey: ._children)
        self.__parent = try container.decodeIfPresent(AnalysisNode.self, forKey: .__parent)
        self._gate = try container.decode(CodableIgnored<AnyGate>.self, forKey: .gate)
        self._color = try container.decode(CodableIgnored<Color>.self, forKey: .color)
        self._opacity = try container.decode(Double.self, forKey: ._opacity)
        self._labelOffset = try container.decode(CGPoint.self, forKey: ._labelOffset)
        self._invert = try container.decode(Bool.self, forKey: ._invert)
    }
    
    public init(children: [AnalysisNode]? = nil)  {
        if let children {   self.children = children  }
    }
    
    public init(sample: Sample)  {
        self.sample  = sample
    }
    
    public init(gate: AnyGate? = nil, invert: Bool = false, color: Color? = nil, opacity: Double = 0.2) {
        self.gate = gate
        self.invert = invert
        self.color = color ?? .green
        self.opacity = opacity
    }
    
    public init(_ original:  AnalysisNode ) {
        self.gate = original.gate
        self.description = original.description
        self.sample = original.sample
        self.graphDef = original.graphDef
        self.statistics = [:]
        self.children = []
        self.parent = nil
        self.gate = original.gate
        self.invert = original.invert
        self.color = original.color ?? .green
        self.opacity = original.opacity
   }


        //--------------------------------------------------------
    @MainActor
    public func getSample() -> Sample?
    { 
        let s: Sample? = sample ?? parent?.getSample()
        
        if s != nil {
            print(s!.tubeName)
        }
        else { print("null sample")}
        return s
        
    }       //AT?
    @MainActor
    public func getSampleMeta() -> FCSMetadata? { getSample()?.meta }
    
    public func path() -> String { return "/" + (parent?.path() ?? name)  }
    
    public func depth() -> Int {
        return (parent == nil) ? 0 :  1 + parent!.depth()
    }                                            
        
    public func cloneDeep() -> AnalysisNode
    {
        let newNode = AnalysisNode(self)
        for child in children {
            newNode.addChild(child.cloneDeep())
        }
        return newNode
    }
    
    public func ancestry() -> [AnalysisNode] {
        var ancestry = [AnalysisNode]()
        var node:AnalysisNode? = self
        while node != nil {
            ancestry.append(node!)
            node = node!.parent
        }
        return ancestry.reversed()
    }

//    public struct MyImage : Identifiable
//    {
//        public var id =  UUID()
//        public var image: NSImage
//        
//        init (_ nsImage: NSImage)   {
//            self.image = nsImage
//        }
//    }
//    public func parentImages() -> [MyImage] {                  //AT?
//        if (parent == nil)  { return [] }
//        var ancestry = parent!.parentImages()
//        if let img = parentImage {
//            ancestry.append(MyImage(img))
//        }
//        return ancestry
//    }
    
//--------------------------------------------------------
//    public func mean(dim: String) -> Double     {   statLookup( EStatistic.mean, dim)    }
//    public func median(dim: String) -> Double   {   statLookup( EStatistic.median, dim)   }
//    public func cv(dim: String) -> Double       {   statLookup( EStatistic.cv, dim)   }
//    public func stdev(dim: String) -> Double    {   statLookup( EStatistic.stdev, dim)   }
//    public func freqOfParent() -> Double        {   statLookup( EStatistic.freqOf, "")    }
//    
//    private func statLookup(_ stat: EStatistic, _ dim: String) -> Double   //AT?
//    {
//        let term = stat.text + dim
//        var value: Double? =  statistics[term]
//        if (value == nil)
//        {
//            value = 2.9   //requestStatQuery(path: path(), stat: stat, dim: dim)
//            statistics[term] = value
//        }
//        return value!
//    }
//--------------------------------------------------------
    public func getChildren() -> [AnalysisNode]     {        children   }

  
    private func _addChild(_ node:AnalysisNode)     {        children.append(node)    }
    public func addChild(_ node:AnalysisNode)       {        node.parent = self  }      // setter adds node as a child
    
    public func addChildDeep(_ node:AnalysisNode)
    {
        for child in node.children {   addChildDeep(child)    }
        if name != node.name {
            addChild(AnalysisNode(node))
        }
    }

    private func _removeChild(_ node: AnalysisNode) {        children.removeAll { $0 == node }    }
    public func remove() {   parent = nil  }     // Removes this child from parent in the parent setter
    public func removeChild(_ node: AnalysisNode?) -> Bool {
        guard let node else {    return false     }
        if node.parent == self {
            node.parent = nil
            return true
        }
        return false
    }

    public func mergeTree(_ clone: AnalysisNode)
    {
        print ("mergeTree")
        if name != clone.name {
            addChild(clone)
        }
        else {  children.append(contentsOf: clone.children) }
    }

//--------------------------------------------------------
    @MainActor
    public func createRequest() throws -> PopulationRequest {
        // AM could lead to undefined behavior if sample/gate are not set as expected
        if let gate, let parent {
            return .gated(try parent.createRequest(), gate: gate, invert: invert, name: name)
        }
        if let sample = getSample(),
           let sampleRef = sample.ref {
            return .sample(sampleRef)
        }
        throw AnalysisNodeError.noSampleRef
    }
 
     public func chartAnnotation(chart: ChartDef?, dims:Tuple2<CDimension?>) -> ChartAnnotation? {
        guard let gate = gate,
              let gate = gate as? any ViewableGate,
              gate.isValid(for: dims)
        else {    return nil   }
        
        return ChartAnnotation(
            id:id.uuidString,
            name: "\(name) gate",
            view: { chartSize, editing in
                gate.chartView(self, chartSize:chartSize, chartDims:dims)
            }, remove: self.remove
        )
    }
 
    @MainActor
    public func visibleChildren(_ chartDef:ChartDef) -> [ChartAnnotation] {
        let dims = getChartDimensions(chartDef)
        let result = children.compactMap { child in
            child.chartAnnotation(chart: chartDef, dims:dims)
        }
        return result
    }
   
    @MainActor
    public func getChartDimensions(_ chartDef:ChartDef?) -> Tuple2<CDimension?> {
        guard let chartDef, let sampleMeta = getSampleMeta() else {
            return .init(nil, nil)
        }
        
        let xAxis = chartDef.xAxis?.dim
        let yAxis = chartDef.yAxis?.dim
        
        return .init(
            sampleMeta.parameter(named: xAxis.nonNil),
            sampleMeta.parameter(named: yAxis.nonNil)
        )
    }
    
}
