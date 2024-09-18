//
//  AnalysisTree.swift
//  filereader
//
//  Created by Adam Treister on 7/25/24.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers.UTType
import CytegeistLibrary
import Combine


//---------------------------------------------------------
//public struct Statistic : Codable, Hashable
//{
//    var extraAttributes = AttributeStore()
//        // operation  (.median, .cv, )
//        // parameters ($3,  ["APC"] )
//        // currentValue  (.undefined)
//    
//    init()
//    {
//        
//    }
//}

public extension UTType {
    static var analysisNode = UTType(exportedAs: "cytegeist.nodes.analysis")
}

enum AnalysisNodeError : Error {
    case noSampleRef
}

//---------------------------------------------------------
public class AnalysisNode : CNamedObject
{

    @Published public var graphDef =  ChartDef()              // how this population wants to be shown
//    public var statistics =  [Statistic]()         // what to report
    @Published private var _parent: AnalysisNode?
    public var parent: AnalysisNode? {
        get { _parent }
        set {
            if newValue == parent {
                return
            }
            if let _parent {
                _parent._removeChild(self)
            }
            _parent = newValue
            if let _parent {
                _parent._addChild(self)
            }
        }
    }
    @Published public private(set) var children: [AnalysisNode] = []        // subpopulations dependent on us
    public var extraAttributes = AttributeStore()
    
    
    public func getSample() -> Sample? { fatalError("Must be overriden") }
    
    private func _addChild(_ node:AnalysisNode) {
        children.append(node)
    }
    public func addChild(_ node:AnalysisNode) {
        node.parent = self
        
    }
    
    public func createRequest() throws -> PopulationRequest { fatalError("Implement") }
    
    public func getChildren<T:AnalysisNode>() -> [T] {
        children.compactMap { $0 as? T }
    }
    
    public func chartView(chart: ChartDef, dims:Tuple2<CDimension?>) -> ChartAnnotation? {
        nil
    }
    
    private func _removeChild(_ node: AnalysisNode) {
        children.removeAll { $0 == node }
    }
        
    public func removeChild(_ node: AnalysisNode?) -> Bool {
        guard let node else {
            return false
        }
        
        if node.parent == self {
            node.parent = nil
            return true
        }
        return false
    }

    public func remove() {
        parent = nil
    }
}

public class SampleNode : AnalysisNode {
    @Published public private(set) var sample:Sample? = nil

    public override func getSample() -> Sample? { sample }
    
    convenience init(_ sample: Sample) {
        self.init()
        self.sample = sample
        self.name = "All Cells"
    }
    
    public override func createRequest() throws -> PopulationRequest {
        guard let ref = sample?.ref else {
            throw AnalysisNodeError.noSampleRef
        }
        return .sample(ref)
    }
}

//@Observable
public class GroupNode : AnalysisNode {
}

//@Observable
public class PopulationNode : AnalysisNode {
    
    @Published public var gate:AnyGate? = nil                      // the predicate to filter ones parent
    @Published public var invert: Bool = false
    @Published public var color: Color = .green
    @Published public var opacity: Double = 0.2
    
    /// Label offset from center of gate in chart 0-1 scale coordinates
    @Published public var labelOffset: CGPoint = .zero
//    
//    public init(gate: AnyGate? = nil, invert: Bool = false, color: Color? = nil, opacity: Double = 0.2) {
//        self.gate = gate
//        self.invert = invert
//        self.color = color ?? .green
//        self.opacity = opacity
//        super.init()
//    }

    public override func getSample() -> Sample? { parent?.getSample() }

    public override func createRequest() throws -> PopulationRequest {
        guard let parent = parent else {
            throw AnalysisNodeError.noSampleRef
        }
        
        return .gated(try parent.createRequest(), gate: gate, invert: invert, name: name)
    }
    
    override public func chartView(chart: ChartDef, dims:Tuple2<CDimension?>) -> ChartAnnotation? {
        guard let gate = gate,
              let gate = gate as? any ViewableGate,
              gate.isValid(for: dims)
        else {
            return nil
        }
        
        return ChartAnnotation(
            id:id.uuidString,
            name: "\(name) gate",
            view: { chartSize, editing in
                gate.chartView(self, chartSize:chartSize, chartDims:dims)
            }, remove: self.remove
            )
    }
}
