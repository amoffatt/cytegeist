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
}

//extension Experiment {
//static var placeholder: Self {
//    Experiment(id: UUID().uuidString, year: 2021, name: "TCell Differentiation", version: "0.012") as! Self
//}
//}
//---------------------------------------------------------

    struct CGroup  : Codable
    {
        var attributes = AttributeStore()
       var name = ""
        var annotation = ""
        var criteria = [Criterion]()
        var members = [Sample]()
        var graph = ChartDef()
        
//        init(from decoder: any Decoder) throws {
//
//        }

        init()
        {
            
        }
        init(fjxml: TreeNode)
        {
            attributes.merge(fjxml.attrib, uniquingKeysWith: +)
            if let grop = fjxml.findChild(value: "Group")
            {
                 for node in grop.children where node.value == "Criteria"
                {
                    criteria.append(Criterion(fjxml: node))
                }
                print ("Group Criteria: " , criteria.count)
           }
            if let grph = fjxml.findChild(value: "Graph")
            {
                graph = ChartDef(fjxml:grph)
                print ("Graph: " , grph.value)
            }
        }
        
        init(name: String = "GROUP", annotation: String = "", criteria: [Criterion]) {
            self.name = name
            self.annotation = annotation
            self.criteria = criteria
        }
    }


extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}


