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
import CytegeistCore


//---------------------------------------------------------
public struct Statistic : Codable, Hashable
{
    var extraAttributes = AttributeStore()
        // operation  (.median, .cv, )
        // parameters ($3,  ["APC"] )
        // currentValue  (.undefined)
    
    init()
    {
        
    }
}

public extension UTType {
    static var population = UTType(exportedAs: "cytegeist.population")
}

enum AnalysisNodeError : Error {
    case noSampleRef
}

//---------------------------------------------------------
@Observable
public class AnalysisNode : Codable, Transferable, Identifiable, Hashable, Equatable
{
    
    public static func == (lhs: AnalysisNode, rhs: AnalysisNode) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public var id = UUID()
    public var name: String = ""
    public var graphDef =  ChartDef()              // how this population wants to be shown
    public var statistics =  [Statistic]()         // what to report
    public var children: [AnalysisNode]?  =  [AnalysisNode]()        // subpopulations dependent on us
    public var extraAttributes = AttributeStore()
    
    public private(set) var parent: AnalysisNode?

    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: UTType.population)
    }
    
        // removeChild
        // gate.clear()
        // graphDef.edit
    public init()
    {
    }
    public init(children: [AnalysisNode]? = nil)
    {
        if let children {
            self.children = children
        }
    }
    
    
    public func getSample() -> Sample? { fatalError("Must be overriden") }
    
    public func addChild(_ node:AnalysisNode) {
        if children == nil {
            children = []
        }
        children!.append(node)
        
        node.parent = self
    }
    
    public func createRequest() throws -> PopulationRequest { fatalError("Implement") }
    
    public func getChildren<T:AnalysisNode>() -> [T] {
        if let children {
            return children.compactMap { $0 as? T }
        }
        return []
    }
    
    public func chartView(chart: ChartDef) -> ChartAnnotation? {
        nil
    }
}

@Observable
public class SampleNode : AnalysisNode {
    public let sample:Sample

    public override func getSample() -> Sample { sample }
    
    init(_ sample: Sample) {
        self.sample = sample
        super.init()
        self.name = "All Cells"
    }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    public override func createRequest() throws -> PopulationRequest {
        guard let ref = sample.ref else {
            throw AnalysisNodeError.noSampleRef
        }
        return .sample(ref)
    }
}

@Observable
public class GroupNode : AnalysisNode {
}

@Observable
public class PopulationNode : AnalysisNode {
    public var gate:AnyGate?                      // the predicate to filter ones parent
    public var invert: Bool
    public var color: Color
    public var opacity: Float
    
    public init(gate: AnyGate? = nil, invert: Bool = false, color: Color? = nil, opacity: Float = 0.2) {
        self.gate = gate
        self.invert = invert
        self.color = color ?? .green
        self.opacity = opacity
        super.init()
    }
    
    public required init(from decoder: any Decoder) throws {
        fatalError()
    }

    public override func getSample() -> Sample? { parent?.getSample() }

    public override func createRequest() throws -> PopulationRequest {
        guard let parent = parent else {
            throw AnalysisNodeError.noSampleRef
        }
        
        return .gated(try parent.createRequest(), gate: gate, invert: invert, name: name)
    }
    
    override public func chartView(chart: ChartDef) -> ChartAnnotation? {
        guard let gate = gate else {
            return nil
        }
        
        let gateBinding = Binding<AnyGate?>() {
            gate
        } set: {
            self.gate = $0
        }
        
        return gate.chartView(gateBinding, id: id.uuidString, chart: chart)
    }
}
