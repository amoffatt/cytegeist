//
//  Workspace.swift
//  filereader
//
//  Created by Adam Treister on 7/19/24.
//

import Foundation
import Combine
import CytegeistLibrary
import CytegeistCore
import SwiftUI
//import SwiftData

@Observable
//@Transient
class AnalysisNodeSelection: Codable {
    var nodes: Set<AnalysisNode> = []
    var first:AnalysisNode? { nodes.first }
}

//-----------------------------------------------
@Observable
//@Model
public class Experiment : Usable
{
//    @Environment var appModel
    
    public static func == (lhs: Experiment, rhs: Experiment) -> Bool { lhs.id == rhs.id   }
    
    public var id = UUID()
    
    let version: String
    var creationDate: Date = Date.now
    var modifiedDate: Date = Date.now
    var name = "All Samples"
    var mode: SampleListMode = SampleListMode.table
    var reportMode: ReportMode = ReportMode.gating

    var samples: [Sample] = [Sample]()
    var selectedSamples = Set<Sample.ID>()
//    @Transient   
    var selectedAnalysisNodes = AnalysisNodeSelection()
    
    var panels = [CPanel]()
    var groups = [CGroup]()
    var tables = [CGTable]()
    var layouts = [CGLayout]()
    
//    @Transient 
    var core: CytegeistCoreAPI = CytegeistCoreAPI()

//  @Transient
//    var _core: CytegeistCoreAPI?
//
//    var core: CytegeistCoreAPI {       /// Lazilly created
//        if let _core {  return _core   }
//        _core = CytegeistCoreAPI()
//        return _core!
//    }
        //--------------------------------------------------------------------------------
    required public init(from decoder: any Decoder) throws {
        self.version = "-02"
       fatalError("Implement decoding")        // TODO AM Write class macro and property wrapper to handle properties with default values
    }
    
    init(name: String = "Untitled", version: String = "" )
    {
        print("Experiment \(name) ")
        self.version = version
        self.name = name.isEmpty ? DateStr(Date.now) : name
    }
    public func encode(to encoder: Encoder) throws {
            // Do nothing
    }
    
    func DateStr(_ date: Date) -> String
    {
        let myDateFormatter = DateFormatter()
        myDateFormatter.dateFormat = "YYMMDD"
        return myDateFormatter.string(from: date)
    }
        //--------------------------------------------------------------------------------
    
    func addTable() -> CGTable {
        let table = CGTable()
        table.name = table.name.generateUnique(existing: tables.map { $0.name })
        tables.append(table)
        return table
    }
    
    func addLayout() -> CGLayout {
        let layout = CGLayout()
        layout.name = layout.name.generateUnique(existing: layouts.map { $0.name })
        layouts.append(layout)
        return layout
    }
    
        //--------------------------------------------------------------------------------
    
    public var focusedSample: Sample? {
            // AM TODO currently will be a random item when multiple selected.
            // should be the first in selection, or most recently clicked sample
        self[selectedSamples.first]
    }
    
    public func nextSample(path: String) {     print("Experiment.nextSample " + path)   }
    public func prevSample(path: String) {     print("Experiment.prevSample " + path)    }

    public func clearSampleSelection() {       selectedSamples.removeAll()    }

    public var focusedAnalysisNode: AnalysisNode? {
        let selectedSample = self[selectedSamples.first]
        return selectedAnalysisNodes.first ?? selectedSample?.getTree()
    }
    
    public func clearAnalysisNodeSelection() {     selectedAnalysisNodes.nodes.removeAll()    }
    
    public func setAnalysisNodeSelection(_ node: AnalysisNode ) {
        selectedAnalysisNodes.nodes.removeAll()
        selectedAnalysisNodes.nodes.insert(node)
    }

    public func getSamplesInCurrentGroup() -> [Sample]          // TODO implement group sets
    {
        return samples
    }
    
    
    public func copyToGroup() -> ()   {
        if let root = focusedSample?.getTree() {
            let samplesInGroup = getSamplesInCurrentGroup()
            for sample in samplesInGroup {
                if (sample == focusedSample) { continue }
                sample.getTree().mergeTree(root.cloneDeep())
            }
        }
    }
    
    func editStr(s: String) -> String {
        let len = s.count
        return "\(s.substring(offset: 0, length: 12))...\(s.substring(offset: len-12, length: 12))"
    }
        //--------------------------------------------------------------------------------
        //--------------------------------------------------------------------------------
//    @Transient  
    struct Entry
    {
        var key: String
        var vals: [String] = []
        
        init (_ key: String,_ val: String){
            self.key = key
            self.vals.append(val)
        }
        init (_ keyPair: StringField){
            self.key = keyPair.name
            self.vals.append(keyPair.value)
        }
    }
    
//   @Transient 
    var keywords = [String]()
//   @Transient 
    var entries = [Entry]()
    
    public func buildVaribleKeyDictionary() /// -> [Entry]
    {
        var union: [Entry] = []
        var allKeywords: Set<String> = []
        for sample in samples {
            if let keywords = sample.meta?.keywords.filter( {!isParameterKey($0.name) && !isExcludedKey($0.name) } )           // exclude parameter keywords
            {
                for s in keywords {
                    allKeywords.insert(s.name)
                }
        
                for keyPair in keywords {
                    if let entry = union.firstIndex(where: { $0.key == keyPair.name} ) {
                        union[entry].vals.append(keyPair.value)
                    }
                    else {   union.append(Entry(keyPair))  }
                }
            }
        }

//        let ct = union.count            // number of keywords in all samples

        keywords.append(contentsOf: allKeywords)
        entries.append(contentsOf: union)

        let sampleCt = samples.count
        let multivals = union.filter( { Set($0.vals).count > 1 })
        let uniques = multivals.filter( { Set($0.vals).count == sampleCt })
        let nonuniques = multivals.filter( { Set($0.vals).count < sampleCt })
        
        print("Uniques: ", uniques.map({ $0.key}))
        print("Nonuniques: ", nonuniques.map({ $0.key}), nonuniques.map({ Set($0.vals) }))
 //       return nonuniques
    }
    
    
    func isParameterKey(_ keyword: String) -> Bool
    {
        keyword.starts(with: "$P")      // should check for a digit in 3rd position
    }
    func isExcludedKey(_ keyword: String) -> Bool
    {
        if  ["$BEGINDATA", "$ENDDATA", "$TOT", "$COMP", "$BTIM", "$ETIM"].contains(keyword)    {
             return true
         }
        return false
    }

    subscript(sampleId: Sample.ID?) -> Sample? {
        get {
            if let id = sampleId {  return samples.first(where: { $0.id == id })  }
            return nil
        }
    }
}

    //--------------------------------------------------------------------------------
public struct CGroup : Identifiable, Codable
{
    public var id = UUID()
    var name = ""
    var keyword: String?
    var value: String?
    @CodableIgnored
    var color: Color?
    
    init(name: String = "name", color: Color?, keyword: String?, value:  String?) {
        self.name = name
        self.color = color
        self.keyword = keyword
        self.value = value
    }
}
    //--------------------------------------------------------------------------------
struct CPanel : Usable
{
    var id = UUID()
    var name = ""
    var keyword: String?
    var values: [String]
    @CodableIgnored
    var color: Color?
    
     public static func == (lhs: CPanel, rhs: CPanel) -> Bool {   lhs.id == rhs.id   }

    init(name: String = "name", color: Color?, keyword: String?, values:  String?) {
        self.name = name
        self.color = color
        self.keyword = keyword
        self.values = []
    }
}
