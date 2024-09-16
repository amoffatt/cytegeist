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
import SwiftData

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
    var tables = [CGTableModel]()
    var layouts = [CGLayoutModel]()
    
        //    @ObservationIgnored
        //    @CodableIgnored
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
    
    init(name: String = "Untitled", version: String = "" )
    {
        print("Experiment \(name) ")
        self.name = name
        self.version = version
    }
    public func encode(to encoder: Encoder) throws {
            // Do nothing
    }
        //--------------------------------------------------------------------------------
    func addTable() -> CGTableModel {
        let table = CGTableModel()
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
    
    
    public func addSample(_ sample: Sample)
    {
        samples.append(sample)
            //        print("Added Sample: \(sample.tubeName) collected on   \(sample.date) Count: \(samples.count) to experiment \(id)")
        
    }
        //--------------------------------------------------------------------------------
    
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
        //--------------------------------------------------------------------------------
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
        //--------------------------------------------------------------------------------
    
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
        //--------------------------------------------------------------------------------
    public struct Entry
    {
        var key: String
        var vals: [String] = []
        
        init (_ key: String,_ val: String)
        {
            self.key = key
            self.vals.append(val)
        }
    }
    
    public func buildVaribleKeyDictionary() -> [Entry]
    {
        var union: [Entry] = []
        for sample in samples {
            var keywords = sample.meta?.keywords.filter( {!isParameterKey($0.name) } )           // exclude parameter keywords
            for keyPair in keywords! {
                if let entry = union.firstIndex(where: { $0.key == keyPair.name} ) {
                    union[entry].vals.append(keyPair.value)
                }
                else {   union.append(Entry(keyPair.name,keyPair.value))  }
            }
        }
        
        
        let ct = union.count            // number of keywords in all samples
        let sampleCt = samples.count
        
            //        let globals = union.filter( { Set($0.vals).count == sampleCt })
        let multivals = union.filter( { Set($0.vals).count > 1 })
        let uniques = multivals.filter( { Set($0.vals).count == sampleCt })
        let nonuniques = multivals.filter( { Set($0.vals).count < sampleCt })
        
        print("Uniques: ", uniques)
        print("Nonuniques: ", nonuniques)
        return nonuniques
    }
    
        //
    
    func isParameterKey(_ keyword: String) -> Bool
    {
        keyword.starts(with: "$P")      // should check for a digit in 3rd position
    }
    
    
    
    subscript(sampleId: Sample.ID?) -> Sample? {
        get {
            if let id = sampleId {
                return samples.first(where: { $0.id == id })!
            }
            return nil
        }
    }
    
    
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
        //--------------------------------------------------------------------------------
}


public struct CGroup : Identifiable, Codable
{
        //        var attributes = [String : String]()
        //        var annotation = ""
        //        var criteria = [Criterion]()
        //        var members = [Sample]()
        //        var graph = GraphDef()
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





    
    
        //        set(newValue) {
        //            if let index = samples.firstIndex(where: { $0.id == newValue.id }) {
        //                samples[index] = newValue
        //            }
        //        }
    
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

    //extension Experiment {
    //static var placeholder: Self {
    //    Experiment(id: UUID().uuidString, year: 2021, name: "TCell Differentiation", version: "0.012") as! Self
    //}
    //}
