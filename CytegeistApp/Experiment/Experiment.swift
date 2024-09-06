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

@Observable
class AnalysisNodeSelection: Codable {
    var nodes: Set<AnalysisNode> = []
    
    var first:AnalysisNode? { nodes.first }
}

//-----------------------------------------------
@Observable
public class Experiment : Usable
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
    var selectedAnalysisNodes = AnalysisNodeSelection()
    
    var panels = [CPanel]()
    var groups = [CGroup]()
    var tables = [CGTable]()
    
    var layouts = [CGLayout]()
    
    @ObservationIgnored
    @CodableIgnored
    var _core:CytegeistCoreAPI? = nil
    /// Lazilly created
    var core:CytegeistCoreAPI {
        if let _core {
            return _core
        }
        _core = CytegeistCoreAPI()
        return _core!
    }
    required public init(from decoder: any Decoder) throws {
        fatalError("Implement decoding")        // TODO AM Write class macro and property wrapper to handle properties with default values
        
    }
    
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


    init(name: String = "Untitled", version: String = "" )
    {
        print("Experiment \(name) ")
        self.name = name
        self.version = version
    }
    
   
    public func addSample(_ sample: Sample)
    {
        samples.append(sample)
//        print("Added Sample: \(sample.tubeName) collected on   \(sample.date) Count: \(samples.count) to experiment \(id)")
        
    }
    
    public var focusedSample: Sample? {
        // AM TODO currently will be a random item when multiple selected.
        // should be the first in selection, or most recently clicked sample
        self[selectedSamples.first]
    }
    
    public func clearSampleSelection() {
        selectedSamples.removeAll()
    }
    
    public var focusedAnalysisNode: AnalysisNode? {
        let selectedSample = self[selectedSamples.first]
        return selectedAnalysisNodes.first ?? selectedSample?.getTree()
    }
    
    public func clearAnalysisNodeSelection() {
        selectedAnalysisNodes.nodes.removeAll()
    }
    
    public func setAnalysisNodeSelection(_ node: AnalysisNode ) {
        selectedAnalysisNodes.nodes.removeAll()
        selectedAnalysisNodes.nodes.insert(node)
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
        
        do  {
            let sample = Sample(ref: SampleRef(url: url))
            sample.setUp(core:core)
            addSample(sample)
        }
//        catch let err as NSError {
//            debug("Ooops! Something went wrong: \(err)")
//        }
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
///*
///
    public struct Entry
    {
        var key: String
        var vals: [String] = []
        
        init ( key: String,  val: String)
        {
            self.key = key
            self.vals.append(val)
        }
    }
//    
//    public func buildVaribleKeyDictionary() -> [Entry]
//    {
//        var union: [Entry]
//        var keywords = meta?.keywords.filter(! $0.starts(with: "$P"))            // exclude parameter keywords
//
//        ForEach (samples) { sample in
//            ForEach (keywords) { keyPair in
//                if let entry = union[keyPair.key] {
//                    entry.vals.append(keyPair.val)
//                }
//                else {
//                    union.addEntry(Entry(keyPair.key,keyPair.val))
//                }
//            }
//        }
//            
//    
//        let ct = union.count            // number of keywords in all samples
//        let sampleCt = samples.count
//        
//        let globals = union.filter( { entry in  entry.vals.ct == sampleCt })
//        let multivals = globals.filter( entry in { entry.vals.reduce().count > 1 })
//        let uniques = multivals.filter( entry in { entry.vals.reduce().count == sampleCt })
//        let nonuniques = multivals.filter( entry in { entry.vals.reduce().count < sampleCt })
//
//        
//        ForEach nonuniques { entry in
//            print(entry.key + " --> " + entry.vals)
//        }
//        return nonuniques
//    }
//}
//     
  


    
 
    subscript(sampleId: Sample.ID?) -> Sample? {
        get {
            if let id = sampleId {
                return samples.first(where: { $0.id == id })!
            }
            return nil
        }
        
//        set(newValue) {
//            if let index = samples.firstIndex(where: { $0.id == newValue.id }) {
//                samples[index] = newValue
//            }
//        }
    }
    
    
    
    func onFCSPicked(_result: Result<[URL], any Error>)
    {
        Task {
            do {
                try print("FCSPicked urls: ", _result.get())
                for url in try _result.get()
                {
                    let gotAccess = url.startAccessingSecurityScopedResource()
                    if !gotAccess { break }
                    await readFCSFile(url)
                    url.stopAccessingSecurityScopedResource()     // release access
                }
            }
            catch let error as NSError {
                debug("Ooops! Something went wrong: \(error)")
            }
        }
    }
    
//    var fcsWaitList: [URL] = []
//    func readFCSFileLater(_ url:URL)
//    {
//        fcsWaitList.append(url)
//    }
//    func processWaitList() async
//    {
//        for url in fcsWaitList {
//            await readFCSFile(url)
//        }
//    }
//    
//    func readFCSFile(_ url:URL) async
//    {
//        let exp = getSelectedExperiment(createIfNil: true)!
//        await exp.readFCSFile(url)
//    }
//    
//    func readFCSFiles(_ urls:[URL]) async
//    {
//        for url in urls  {
//            await readFCSFile(url)
//        }
//    }
}

//extension Experiment {
//static var placeholder: Self {
//    Experiment(id: UUID().uuidString, year: 2021, name: "TCell Differentiation", version: "0.012") as! Self
//}
//}
//---------------------------------------------------------
@propertyWrapper
public struct CodableIgnored<T>: Codable {
    public var wrappedValue: T?
    
    public init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }
    
    public init(from decoder: Decoder) throws {
        self.wrappedValue = nil
    }
    
    public func encode(to encoder: Encoder) throws {
            // Do nothing
    }
}


struct CGroup : Identifiable, Codable
{
        //        var attributes = [String : String]()
        //        var annotation = ""
        //        var criteria = [Criterion]()
        //        var members = [Sample]()
        //        var graph = GraphDef()
    var id = UUID()
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

struct CPanel : Usable
{
    var id = UUID()
    var name = ""
    var keyword: String?
    var values: [String]
    @CodableIgnored
    var color: Color?
    
    
    public static func == (lhs: CPanel, rhs: CPanel) -> Bool {
        lhs.id == rhs.id
    }

    init(name: String = "name", color: Color?, keyword: String?, values:  String?) {
        self.name = name
        self.color = color
        self.keyword = keyword
        self.values = []
    }
}


extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}


