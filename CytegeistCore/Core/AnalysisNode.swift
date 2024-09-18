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
public class AnalysisNode : Codable, Transferable, Identifiable, Hashable
{
    public var id = UUID()
    public var name: String = ""
    public let sample: Sample?                      // nil except at the root node
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
    public var gate: AnyGate?                      // the predicate to filter ones parent
    public var invert: Bool = false
    public var color: Color  = Color.red
    public var opacity: Double = 1.0
    public var labelOffset = CGPoint.zero
//
//--------------------------------------------------------
    public static func == (lhs: AnalysisNode, rhs: AnalysisNode) -> Bool {   lhs.id == rhs.id  }
    public func hash(into hasher: inout Hasher) {        hasher.combine(id)    }
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: UTType.population)
    }
 //--------------------------------------------------------
    public init() {    }
    
    public required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    public init(children: [AnalysisNode]? = nil)  {
        if let children {   self.children = children  }
    }

    init(gate: AnyGate? = nil, invert: Bool = false, color: Color? = nil, opacity: Double = 0.2) {
        self.gate = gate
        self.invert = invert
        self.color = color ?? .green
        self.opacity = opacity
    }
    
 //--------------------------------------------------------
    func getSample() -> Sample? { sample ?? parent?.getSample() }

    func path() -> String { return parent?.path() ?? "" + name  }
//--------------------------------------------------------
    public func mean(dim: String) -> Double     {   statLookup( EStatistic.mean, dim)    }
    public func median(dim: String) -> Double   {   statLookup( EStatistic.median, dim)   }
    public func cv(dim: String) -> Double       {   statLookup( EStatistic.stdev, dim)   }
    public func freqOfParent() -> Double        {   statLookup( EStatistic.freqOf, "")    }
    
    private func statLookup(_ stat: EStatistic, _ dim: String) -> Double
    {
        let term = stat.text + dim
        var value: Double? =  statistics[term]
        if (value == nil)
        {
            value = 2.9   //requestStatQuery(path: path(), stat: stat, dim: dim)
            statistics[term] = value
        }
        return value!
    }
//--------------------------------------------------------
    private func _addChild(_ node:AnalysisNode)     {        children.append(node)    }
    public func addChild(_ node:AnalysisNode)       {        node.parent = self    }
    public func getChildren() -> [AnalysisNode]     {        children   }
    private func _removeChild(_ node: AnalysisNode) {        children.removeAll { $0 == node }    }
    public func removeChild(_ node: AnalysisNode?) -> Bool {
        guard let node else {    return false     }
        if node.parent == self {
            node.parent = nil
            return true
        }
        return false
    }

    public func remove() {
        if parent != nil { _ = parent!.removeChild(self)  }
        parent = nil
    }

//--------------------------------------------------------
     func createRequest() throws -> PopulationRequest {
        guard let parent = parent else {
            throw AnalysisNodeError.noSampleRef
        }
        return .gated(try parent.createRequest(), gate: gate, invert: invert, name: name)
    }
    
     public func chartView(chart: ChartDef, dims:Tuple2<CDimension?>) -> ChartAnnotation? {
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
}
