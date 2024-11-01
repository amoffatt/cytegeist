//
//  Workspace.swift
//  filereader
//
//  Created by Adam Treister on 7/19/24.
//

import Foundation
import Combine
import Synchronization
import CytegeistLibrary
import CytegeistCore
import SwiftUI
import SwiftData
import CObservation
import UniformTypeIdentifiers

//@MainActor
//@CObservable
@CObservable
class AnalysisNodeSelection: CObject {
    
    // AM DEBUGGING
    var nodes: Set<AnalysisNode> = [] //{ [] }
    var first:AnalysisNode? { nodes.first }
    
//    public override init() {
////        self.nodes = []
//    }
}

//@CObservable
//class AnalysisNodeSelectionTest: CObject {
//    
//    // AM DEBUGGING
////    var nodes: Set<AnalysisNode> //{ [] }
//    var node:SampleRef?
//    
//    required init(from decoder: any Decoder) async throws {
//        try await super.init(from: decoder)
//    }
////    var first:AnalysisNode? { nodes.first }
//    
////    public override init() {
//////        self.nodes = []
////    }
//}

extension UTType {
    static var cge: UTType = .init(filenameExtension: "cge")!
}

@Observable
@MainActor
public class CDocument {

    public static let readableContentTypes: [UTType] = [.cge]
    public static let writableContentTypes: [UTType] = [.cge]

    public private(set) var content: Experiment!
    public let context = CObjectContext(nil)
    public private(set) var isTemporaryURL: Bool = true
    private var _url: URL
    public var url: URL {
        get { _url }
        set { _url = newValue; isTemporaryURL = false }
    }
    public init() {
        
        // self.content = try! runOnMainThreadBlocking {   // AM try! because runOnMainThreadBlocking can't support swift 'rethrows' behavior
        content = self.context.withContext {
             Experiment()
        }
        _url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    }
    
    private func snapshot() throws -> Any? {
        print("Beginning document snapshot...")
        
//        let result = try runOnMainThreadBlocking {
//            let result = try self.content.serialize()
//        }
        // We can serialize from outside the MainActor because the main actor is waiting on this function, so the model will not be changed or read at the same time
        let result = try content.serialize()
        print(" ==> document snapshot complete.")
        return result
    }
    
    public func fileWrapper(snapshot: Any?) throws -> FileWrapper {
        guard let snapshot else {
            throw DocumentError.documentNotSerialized
        }
//        let encoder = JSONEncoder()
//        await snapshot.encode(to: encoder)
//        let data = try encoder.e/*n*/code(AsyncMainActorCodableWrapper(snapshot))
        let options = JSONSerialization.WritingOptions.prettyPrinted
        let data = try JSONSerialization.data(withJSONObject: snapshot, options: options)
        print("Serialized document:\n\(String(decoding: data, as: Unicode.UTF8.self))")
        return FileWrapper(regularFileWithContents: data)
    }

    func save(_ callback: @escaping (CDocument, Error?) -> Void) {
        do {
            try fileWrapper(snapshot: try snapshot()).write(to: url, options: .atomic, originalContentsURL: nil)
            callback(self, nil)
        } catch {
            print("Error saving document: \(error)")
            callback(self, error)
        }
    }

}

//public struct AsyncMainActorCodableWrapper<T:MainActorSerializable> : Codable {
//    public let content: T?
//    
//    public init(_ content: T?) {
//        self.content = content
//    }
//    
//    public init(from decoder: any Decoder) throws {
//        var tempContent: T?
//        let container = try decoder.singleValueContainer()
//        let decodedContent = try container.decode(T.self)
//        
//        // Use async/await properly
//        let group = DispatchGroup()
//        group.enter()
//        
//        Task {
//            tempContent = decodedContent
//            group.leave()
//        }
//        
//        group.wait()
//        self.content = tempContent
//    }
//    
//    public func encode(to encoder: any Encoder) throws {
//        
//    }
//}


//-----------------------------------------------
@CObservable
public class Experiment : CObject
{
    var version: String? = "0.01"
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
    var _core: CytegeistCoreAPI? = nil
    
    var core: CytegeistCoreAPI {       /// Lazilly created
        if let _core {  return _core   }
        _core = CytegeistCoreAPI()
        return _core!
    }
    
    init(name: String = "Untitled", version: String = "" )
    {
        print("Experiment \(name) ")
        self.name = name
        self.version = version
        super.init()
    }
    
        //--------------------------------------------------------------------------------
    public func addSample(_ sample: Sample)   {
        samples.append(sample)
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
            let sample = withContext { Sample(ref: SampleRef(url: url)) }
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
                    } else {  continuation.yield( fileURL )    }
                }
                continuation.finish()
            }
        }
    }
        //--------------------------------------------------------------------------------
    public struct Entry
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
    
    var keywords = [String]()
    var entries = [Entry]()
    public func buildVaribleKeyDictionary() /// -> [Entry]
    {
        var union: [Entry] = []
        var allKeywords: Set<String> = []
        for sample in samples {
            let keywords = sample.meta?.keywords.filter( {!isParameterKey($0.name) && !isExcludedKey($0.name) } )           // exclude parameter keywords
            for s in keywords! {
                allKeywords.insert(s.name)
            }
           
            for keyPair in keywords! {
                if let entry = union.firstIndex(where: { $0.key == keyPair.name} ) {
                    union[entry].vals.append(keyPair.value)
                }
                else {   union.append(Entry(keyPair))  }
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
            if let id = sampleId {  return samples.first(where: { $0.id == id })!  }
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
