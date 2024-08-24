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

//---------------------------------------------------------
@Observable
public class AnalysisNode : Codable, Transferable, Identifiable, Equatable
{

    public static func == (lhs: AnalysisNode, rhs: AnalysisNode) -> Bool {
         lhs.id == rhs.id
    }
    
    public var id = UUID()
    var name = ""
    var graphDef =  ChartDef()              // how this population wants to be shown
    var gate =  Gate()                      // the predicate to filter ones parent
    var statistics =  [Statistic]()         // what to report
    var children: [AnalysisNode]?  =  [AnalysisNode]()        // subpopulations dependent on us
    var extraAttributes = AttributeStore()
    
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: UTType.population)
    }

        // addChild
        // removeChild
        // gate.clear()
        // graphDef.edit
    init()
    {
    }
    init(name: String, children: [AnalysisNode]? = nil)
    {
        self.name = name
        if let children {
            self.children = children
        }
    }

    
        func addChild(_ node:AnalysisNode) {
            if children == nil {
                children = []
            }
            children!.append(node)
        }
    }



    //-------------------------------------------------------------------------------
    // hardcoded data for an outline group

let sections = [ AnalysisNode(name: "Cytometry Protocols", children: pops),
                 AnalysisNode(name: "Image Analysis", children: pops),
                 AnalysisNode(name: "Single Cell Analysis", children: tree)
]
let pops = [ AnalysisNode(name: "CD4"),
             AnalysisNode(name: "CD8"),
             AnalysisNode(name: "CD45"),
             AnalysisNode(name: "CD19")
]
let tree = [ AnalysisNode(name: "CD34",  children: [ AnalysisNode(name: "Leva X"), AnalysisNode(name: "Leva S") ]),
             AnalysisNode(name: "BCells", children: [ AnalysisNode(name: "Strada EP" ),
                                                                          AnalysisNode(name: "Strada AV" ),
                                                                          AnalysisNode(name: "Strada MP"),
                                                                          AnalysisNode(name: "Strada EE") ]),
             AnalysisNode(name: "KB90"),
             AnalysisNode(name: "TCells", children: [ AnalysisNode(name: "Linea PB X"),
                                                                           AnalysisNode(name: "Linea PB"),
                                                                           AnalysisNode(name: "Linea Classic") ]),
             AnalysisNode(name: "CD45"),
             AnalysisNode(name: "CD3", children: [ AnalysisNode(name: "CD4"),
                                                                 AnalysisNode(name: "CD8") ])
]
