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

//-----------------------------------------------
@Observable
public class Experiment :  Codable, Identifiable, Equatable
{
    public static func == (lhs: Experiment, rhs: Experiment) -> Bool {
        lhs.id == rhs.id
    }
    
    public var id = UUID()
    
    var version:String? = "0.01"
    var creationDate:Date = Date.now
    var modifiedDate:Date = Date.now
//    var curGroup:String? = "All Samples"
    var name = "All Samples"

    var samples:[Sample] = [Sample]()
    var selectedSamples = Set<Sample.ID>()
    var groups = [CGroup]()
    var tables = [TableSchema]()
    var layouts = [CGLayoutModel]()
    //        var columns : [TableColumn]     // the layout of the workspace window
    
    //    var _cytometers: [Cytometer]     // ignore
    //    var _matrices: [Matrix]          // ignore
    //    var _exports: [String]           // ignore
    //    var _scripts: [String]          // ignore
    //    var _history: [String]          // ignore
    required public init(from decoder: any Decoder) throws {
        fatalError("Implement decoding")        // TODO AM Write class macro and property wrapper to handle properties with default values
        
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.id = try container.decode(UUID.self, forKey: .id)
//        self.version = try container.decodeIfPresent(String.self, forKey: .version)
//        self.creationDate = try container.decodeIfPresent(String.self, forKey: .creationDate)
////        self.curGroup = try container.decodeIfPresent(String.self, forKey: .curGroup)
//        self.year = try container.decodeIfPresent(Int.self, forKey: .year)
//        self.name = try container.decode(String.self, forKey: .name)
//        self.samples = try container.decode([Sample].self, forKey: .samples)
        
//        if let groups = try container.decodeIfPresent([CGroup].self, forKey: .groups) {
//            self.groups = groups
//        }
//        self.tables = try container.decodeIfPresent([TableSchema].self, forKey: .tables)
//        self.layouts = try container.decodeIfPresent([LayoutSchema].self, forKey: .layouts)
    }
    

    init(name: String = "Untitled", version: String = "" )
    {
   print("Experiment \(name) ")
        self.name = name
        self.version = version
    }
    
   
    public func addSample(_ sample: Sample)
    {
        samples.append(sample)
        sample.setUp()
        print("Added Sample: \(sample.tubeName) collected on   \(sample.date) Count: \(samples.count) to experiment \(id)")
        
    }
  
    public func readFCSFile(_ url: URL) async
    {
        if  url.isDirectory
        {
           let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]
            let fcsFiles = walkDirectory(at: url, options: options).filter {  $0.pathExtension == "fcs"  }
            for await item in fcsFiles { await readFCSFile(item) }
            return
        }
        
        let reader = FCSReader()
        do  {
            let fcs = try reader.readFCSFile(at: url,includeData: false)
            addSample(Sample(fcs: fcs))
        }
        catch let err as NSError {
            debug("Ooops! Something went wrong: \(err)")
        }
        debug("FCS Read")
    }

        
  

        // Recursive iteration
    func walkDirectory(at url: URL, options: FileManager.DirectoryEnumerationOptions ) -> AsyncStream<URL> {
        AsyncStream { continuation in
            Task {
                let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil, options: options)
                while let fileURL = enumerator?.nextObject() as? URL {
                    print(fileURL)
                 if fileURL.hasDirectoryPath {
                        for await item in walkDirectory(at: fileURL, options: options) {
                            continuation.yield(item)
                        }
                    } else {
                        continuation.yield( fileURL )
                    }
                }
                continuation.finish()
            }
        }
    }
    
//    
//        // use it
//    let path = URL( string: "<your path>" )
//    
//    let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]
//    
//    Task {
//        
//        let swiftFiles = walkDirectory(at: path!, options: options).filter {
//            $0.pathExtension == "swift"
//        }
//        
//        for await item in swiftFiles {
//            print(item.lastPathComponent)
//        }
//        
//    }

    
    public init(ws: TreeNode )
    {
        print ("Experiment's Tree Count: ", ws.deepCount)
//        let ws = ws.children.first
   //        let samps = ws?.findChild(value: "SampleList")
   //        let gps = ws?.findChild(value: "Groups")
   //        let tabls = ws?.findChild(value: "TableEditor")
   //        let lays = ws?.findChild(value: "LayoutEditor")
   ///
//   /        if let s = samps  { self.processSamples(s)   }
//        if let g = gps    { self.processGroups(g)    }
//        if let t = tabls  { self.processTables(t)    }
//        if let l = lays  { self.processLayouts(l)    }
//        print ("Samples: \(samples.count) Groups: \(groups.count) Tables: \(tables.count) Layouts: \(layouts.count) ")
        
    }
    
    
//    func processSamples(_ xml: TreeNode)
//    {
//        for node in xml.children where node.value == "Sample"  {
//            samples.append(Sample(node))
//        }
//        print("SampleList: ", samples.count)
//    }
//    func processGroups(_ xml: TreeNode)
//    {
//        for node in xml.children where node.value == "GroupNode"  {
//            groups.append(CGroup(node))
//        }
//        print("Groups: ", groups.count)
//    }
//    func processTables(_ xml: TreeNode)
//    {
//        for node in xml.children where  node.value == "Table" {
//            tables.append(TableSchema(node))
//        }
//        print("Tables: ", tables.count)
//    }
//    func processLayouts(_ xml: TreeNode)
//    {
//        for node in xml.children where  node.value == "Layout" {
//            layouts.append(LayoutSchema(node))
//        }
//        print("Layouts: ", layouts.count)
//    }
//    
//    func processMatrices(_ xml: TreeNode)
//    {
//        //IGNORE
//    }
//    func processCytometers(_ xml: TreeNode)
//    {
//        //IGNORE
//    }
//    
    //---------------------------------------------------------
//    var numberOfPlantsNeedingWater: Int {
//        let result = samples.reduce(0) { count, sample in count + (sample.needsWater ? 1 : 0) }
//        print("\(name) has \(result)")
//        for sample in samples {
//            print("- \(sample)")
//        }
//        return result
//    }
//    
//    mutating func water(_ samplesToWater: Set<Sample.ID>) {
//        for (index, sample) in samples.enumerated() {
//            if samplesToWater.contains(sample.id) {
//                samples[index].lastWateredOn = Date()
//            }
//        }
//    }
//    
//    mutating func remove(_ plants: Set<Sample.ID>) {
//        self.plants.removeAll(where: { samples.contains($0.id) })
//    }
//    
//    var displayYear: String  = safeString(self.year)
    
    subscript(sampleId: Sample.ID?) -> Sample {
        get {
            if let id = sampleId {
                return samples.first(where: { $0.id == id })!
            }
            return Sample()
        }
        
        set(newValue) {
            if let index = samples.firstIndex(where: { $0.id == newValue.id }) {
                samples[index] = newValue
            }
        }
    }
}

//extension Experiment {
//static var placeholder: Self {
//    Experiment(id: UUID().uuidString, year: 2021, name: "TCell Differentiation", version: "0.012") as! Self
//}
//}
//---------------------------------------------------------

    struct CGroup  : Codable
    {
        var attributes = [String : String]()
       var name = ""
        var annotation = ""
        var criteria = [Criterion]()
        var members = [Sample]()
        var graph = GraphDef()
        
//        init(from decoder: any Decoder) throws {
//
//        }

        init()
        {
            
        }
        init(_ xml: TreeNode)
        {
            attributes.merge(xml.attrib, uniquingKeysWith: +)
            if let grop = xml.findChild(value: "Group")
            {
                 for node in grop.children where node.value == "Criteria"
                {
                    criteria.append(Criterion(xml: node))
                }
                print ("Group Criteria: " , criteria.count)
           }
            if let grph = xml.findChild(value: "Graph")
            {
                graph = GraphDef(grph)
                print ("Graph: " , grph.value)
            }
        }
        
        init(name: String = "GROUP", annotation: String = "", criteria: [Criterion]) {
            self.name = name
            self.annotation = annotation
            self.criteria = criteria
        }
    }

    struct Criterion : Codable
    {
        var attributes = [String : String]()
        init(xml: TreeNode)
        {
        }
    }
extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}


