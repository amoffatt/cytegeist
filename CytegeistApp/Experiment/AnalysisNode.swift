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
    struct Statistic : Codable, Hashable
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
    var name: String = ""
    var graphDef =  ChartDef()              // how this population wants to be shown
    var statistics =  [Statistic]()         // what to report
    var children: [AnalysisNode]?  =  [AnalysisNode]()        // subpopulations dependent on us
    var extraAttributes = AttributeStore()
    
    public private(set) var parent: AnalysisNode?

    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: UTType.population)
    }
    
        // removeChild
        // gate.clear()
        // graphDef.edit
    init()
    {
    }
    init(children: [AnalysisNode]? = nil)
    {
        if let children {
            self.children = children
        }
    }
    
    
    func getSample() -> Sample? { fatalError("Must be overriden") }
    
    func addChild(_ node:AnalysisNode) {
        if children == nil {
            children = []
        }
        children!.append(node)
        
        node.parent = self
    }
    
    func createRequest() throws -> PopulationRequest { fatalError("Implement") }
}

public class SampleNode : AnalysisNode {
    public let sample:Sample

    override func getSample() -> Sample { sample }
    
    init(_ sample: Sample) {
        self.sample = sample
        super.init()
        self.name = "All Cells"
    }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override func createRequest() throws -> PopulationRequest {
        guard let ref = sample.ref else {
            throw AnalysisNodeError.noSampleRef
        }
        return .sample(ref)
    }
}
public class GroupNode : AnalysisNode {
}

public class PopulationNode : AnalysisNode {
    var gate:Gate?                      // the predicate to filter ones parent

    override func getSample() -> Sample? { parent?.getSample() }

    override func createRequest() throws -> PopulationRequest {
        guard let parent = parent else {
            throw AnalysisNodeError.noSampleRef
        }
        
        return .gated(try parent.createRequest(), gate: gate?.spec, invert: gate?.invert ?? false, name: name)
    }
}
