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
    var selectedAnalysisNodes = AnalysisNodeSelection()
    
    var panels = [CPanel]()
    var groups = [CGroup]()
    var tables = [CGTable]()
    var layouts = [CGLayout]()
    var keywords = AttributeStore()
    var parameters = [String]()         // keep a set of union of all parameter names
//    @Transient
    var core: CytegeistCoreAPI = CytegeistCoreAPI()
    
    var defaultBatchContext: BatchContext { .init(allSamples: samples) }

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
//       fatalError("Implement decoding")        // TODO AM Write class macro and property wrapper to handle properties with default values
    }
    
    init(name: String = "Untitled", version: String = "" )
    {
        print("Experiment \(name) ")
        self.version = version
        self.name = name.isEmpty ? dateStr(Date.now) : name
    }
    public func encode(to encoder: Encoder) throws {
            // Do nothing
    }
  //--------------------------------------------------------------------------------
    
    func addTable() -> CGTable {
        let table = CGTable(isTemplate: true)
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
    
    func addLayout(layout: CGLayout, cells: [LayoutCell])  -> CGLayout {
        let layout = CGLayout(orig: layout, cells: cells)
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
  // streaming
    
    public func xml() -> String {
        
        let sampleStr = "<Samples>\n" + samples.compactMap { $0.xml() }.joined() + "</Samples>\n"
        let panelStr = "<Panels>\n" + panels.compactMap { $0.xml() }.joined() + "</Panels>\n"
        let groupStr = "<Groups>\n" + groups.compactMap { $0.xml() }.joined() + "</Groups>\n"
        let tableStr = "<Tables>\n" + tables.compactMap { $0.xml() }.joined() + "</Tables>\n"
        let layoutStr = "<Layouts>\n" + layouts.compactMap { $0.xml() }.joined() + "</Layouts>\n"
        let subs: String  = sampleStr + panelStr + groupStr + tableStr + layoutStr
        let attr =  attributes()
        let keywords = keywords.xml()
        return "<Experiment " + attr + ">\n" + keywords + subs + "</Experiment>\n"
    }

    public func attributes() -> String {
        return "name=\(self.name) version=\(self.version)"
    }
   //--------------------------------------------------------------------------------

    // TODO
    public func parameterNames() -> [String] {
        return ["<All>", "FS", "SS", "FITC", "PE", "APC", "Cy7-APC"]
    }
        // TODO
   public func populationNames() -> [String] {
        return ["<All>", "All Cells", "Single", "Lymphocytes", "Monocytes", "T Cells", "CD3+", "CD4+", "CD8+"]
    }
    
        // TODO
   public func keywordNames() -> [String] {
        return ["Date", "Tube Name", "Url", "Total", "Investigator", "Stains"]
    }
    

    //--------------------------------------------------------------------------------
    public convenience init(ws: TreeNode )
    {
        self.init()
        print ("Experiment's Tree Count: ", ws.deepCount)
        let ws = ws.children.first
        let samps = ws?.findChild(value: "SampleList")
        let gps = ws?.findChild(value: "Groups")
        let tabls = ws?.findChild(value: "TableEditor")
        let lays = ws?.findChild(value: "LayoutEditor")
        
        if let s = samps  { self.processSamples(s)   }
        if let g = gps    { self.processGroups(g)    }
        if let t = tabls  { self.processTables(t)    }
        if let l = lays  { self.processLayouts(l)    }
        print ("Samples: \(samples.count) Groups: \(groups.count) Tables: \(tables.count) Layouts: \(layouts.count) ")
        
    }

    func processSamples(_ xml: TreeNode)
    {
        for node in xml.children where node.value == "Sample"  {
            samples.append(Sample(xml: node))
        }
        print("SampleList: ", samples.count)
    }
    func processGroups(_ xml: TreeNode)
    {
        for node in xml.children where node.value == "GroupNode"  {
            groups.append(CGroup(xml: node))
        }
        print("Groups: ", groups.count)
    }
    func processTables(_ xml: TreeNode)
    {
        for node in xml.children where  node.value == "Table" {
            tables.append(CGTable(node))
        }
        print("Tables: ", tables.count)
    }
    func processLayouts(_ xml: TreeNode)
    {
        for node in xml.children where  node.value == "Layout" {
            layouts.append(CGLayout(node))
        }
        print("Layouts: ", layouts.count)
    }

    func processMatrices(_ xml: TreeNode)    {   }  //IGNORE
    func processCytometers(_ xml: TreeNode)   {    }//IGNORE
        
   //--------------------------------------------------------------------------------
   //  Entry holds all of the values for a given keyword
    
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
    

//    var keywords = [String]()
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

//        keywords.append(contentsOf: allKeywords)
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
        keyword.starts(with: "$P")      //TODO  should check for a digit in 3rd position
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

