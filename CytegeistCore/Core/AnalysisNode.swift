//
//  AnalysisNode.swift
//
//  Created by Adam Treister on 7/25/24.
//

import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers.UTType
import CytegeistLibrary


public extension UTType {  static var population = UTType(exportedAs: "cytegeist.population")   }
enum AnalysisNodeError : Error {  case noSampleRef      }
//---------------------------------------------------------
//Model
@Observable
public class AnalysisNode : Codable, Transferable, Identifiable, Hashable, CustomStringConvertible
{
    
    public var id = UUID()
    public var name: String = ""
    public var description: String { name }
    public var sampleID: Sample.ID? = nil                      // nil except at the root node
    public var chartDef = ChartDef()              // how this population wants to be shown
    public var statistics =  [String : Double]()         // cache of stats with values
    public private(set) var children: [AnalysisNode] = []        // subpopulations dependent on us
    public var extraAttributes = AttributeStore()              // how this population wants to be shown
    
        // TODO parent should not be encoded/decoded. Value is set when parent decodes its children
    @CodableIgnored
    @ObservationIgnored
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
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys.self)
        try container.encode(_id, forKey: .id)
        try container.encode(_name, forKey: .name)
        try container.encode(_sampleID, forKey: .sampleID)
        try container.encode(_chartDef, forKey: .chartDef)
//        try container.encode(_statistics, forKey: .id)
//        try container.encode(_children, forKey: .id)
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Self.CodingKeys.self)
        self._id = try container.decode(UUID.self, forKey: .id)
        self._name = try container.decode(String.self, forKey: .name)
        self._sampleID = try container.decodeIfPresent(Sample.ID.self, forKey: .sampleID)
        self._chartDef = try container.decode(ChartDef.self, forKey: .chartDef)
//        self._statistics = try container.decode([String : Double].self, forKey: ._statistics)
//        self._children = try container.decode([AnalysisNode].self, forKey: ._children)
//            //        self.__parent = try container.decodeIfPresent(AnalysisNode.self, forKey: .__parent)
//            //        self._gate = try container.decode(CodableIgnored<AnyGate>.self, forKey: .gate)
//        self._color = try container.decode(CodableIgnored<Color>.self, forKey: .color)
//        self._opacity = try container.decode(Double.self, forKey: ._opacity)
//        self._labelOffset = try container.decode(CGPoint.self, forKey: ._labelOffset)
//        self._invert = try container.decode(Bool.self, forKey: ._invert)
    }
    
    enum CodingKeys : CodingKey {
        case id, name, sampleID, chartDef
    }
    
    public init(children: [AnalysisNode]? = nil)  {
        if let children {   self.children = children  }
    }
    
    public init(sample: Sample)  {
        self.sampleID  = sample.id
    }
    
    public init(gate: AnyGate? = nil, invert: Bool = false, color: Color? = nil, opacity: Double = 0.2) {
        self.gate = gate
        self.invert = invert
        self.color = color ?? .green
        self.opacity = opacity
    }
    
    public init(_ original:  AnalysisNode ) {
        self.gate = original.gate
//        self.description = original.description
        self.sampleID = original.sampleID
        self.chartDef = original.chartDef
        self.statistics = [:]
        self.children = []
        self.parent = nil
        self.gate = original.gate
        self.invert = original.invert
        self.color = original.color ?? .green
        self.opacity = original.opacity
   }
    
    
    public func xml() -> String {
        let attributes = attributes()
        let head = "<Population " + attributes + ">\n"
        let graph = chartDef.xml()
        let gate = gate?.xml() ?? ""
        var kids = "<Subpopulations>\n"
        for child in children {   kids.append(child.xml())    }
        let tail = "</Subpopulations>\n</Population>\n"
        return head + graph + gate + kids + tail
    }
    
    public func attributes() -> String {
        let inv = invert ? "true" : "false"
        return "inverted=\(inv)"
    }
    

    convenience init(fjxml: TreeNode)
    {
        self.init()

        extraAttributes.dictionary.merge(fjxml.attrib.dictionary, uniquingKeysWith: +)
        if let gs = fjxml.findChild(value: "Graph")   {
            chartDef = ChartDef(fjxml:gs)
        }
        if let g = fjxml.findChild(value: "Gate")  {
//            gate = Gate(fjxml: g)
        }
        for stat in fjxml.children where (stat.value == "Statistic")  {
//            statistics.append( Statistic(fjxml: stat))
        }
        if let kids = fjxml.findChild(value: "Subpopulations")  {
            addChild(AnalysisNode(fjxml:kids))
        }
    }

        //--------------------------------------------------------
    public func getSampleID() -> Sample.ID?
    {
        return sampleID ?? parent?.getSampleID()
    }       //AT?
    
    public func getSample(_ ctx:BatchContext) -> Sample? {
        guard let sampleID = getSampleID() else {  return nil   }
        
        if let s = ctx.getSample(sampleID) {
//            print("getSample(): \(s.tubeName), ref: \(s.ref?.url ?? URL.applicationDirectory )")
            return s
        }
        print("null sample")
        return nil
    }
    
    public func getSampleMeta(_ ctx:BatchContext) -> FCSMetadata? { getSample(ctx)?.meta }
    
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
        if name != clone.name {  addChild(clone)  }
        else {  children.append(contentsOf: clone.children) }
    }

//--------------------------------------------------------
    public func createRequest(_ ctx:BatchContext) throws -> PopulationRequest {
        // AM could lead to undefined behavior if sample/gate are not set as expected
        if let gate, let parent {
            return .gated(try parent.createRequest(ctx), gate: gate, invert: invert, name: name)
        }
        if let sample = getSample(ctx),
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
 
    public func visibleChildren(_ ctx:BatchContext, _ chartDef:ChartDef) -> [ChartAnnotation] {
        let dims = getChartDimensions(ctx, chartDef)
        let result = children.compactMap { child in
            child.chartAnnotation(chart: chartDef, dims:dims)
        }
        return result
    }
   
    public func getChartDimensions(_ ctx: BatchContext, _ chartDef:ChartDef?) -> Tuple2<CDimension?> {
        guard let chartDef, let sampleMeta = getSampleMeta(ctx) else {
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
