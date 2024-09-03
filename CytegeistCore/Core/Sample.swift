//
//  Sample.swift
//  filereader
//
//  Created by Adam Treister on 7/19/24.
//

import Foundation
import CytegeistLibrary


//---------------------------------------------------------
// CDimension is the analog of a samples parameter
//
// is biexDimension a subclass or does it include a transform
  
public enum SampleError : Error {
    case noRef
    case queryError(Error)
}

//---------------------------------------------------------
@Observable
//@MainActor
public class Sample : Identifiable, Codable, Hashable
{
    public static func == (lhs: Sample, rhs: Sample) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public var id = UUID()
    var sampleId = ""
    
    var ref:SampleRef? = nil
    
    @CodableIgnored
    @ObservationIgnored
    var error:Error? = nil
    
    
//    var attributes = AttributeStore()
//    var dimensions = [CDimension]()
    //    var matrix = CMatrix()
    //    var membership =  [String : PValue]()
    //    var validity = SampleValidityCheck ()
    
    public var imageURL: URL?
    public var meta:FCSMetadata?
    
//    var keywords:AttributeStore { meta?.keywordLookup ?? [:] }
    public subscript(_ keyword:String) -> String { (meta?.keywordLookup[keyword]).nonNil }

    public var eventCount: Int { meta?.eventCount ?? 0 }
 
    public var tubeName: String { self["TUBE NAME"] }
    public var experimentName:  String { self["EXPERIMENT NAME"] }
    public var date: String { self["$DATE"] }
    public var btime:  String = ""//{ meta?.keywordLookup["$BTIM"] ?? "" }
    public var filename:  String { self["$FIL"] }
    public var creator:  String { self["CREATOR"] }
    public var apply:  String { self["APPLY COMPENSATION"] }
    public var threshold:  String { self["THRESHOLD"] }
    public var src:  String { self["$SRC"] }
    public var sys:  String { self["$SYS"] }
    public var cytometer:  String { self["$CYT"] }
    public var setup1:  String { self["CST SETUP STATUS"] }


        //-------------------------------------------------------------------------
    //read from JSON
    
    public required init(from decoder: any Decoder) throws {
        fatalError("AM: Implement decoding")
}
    
        //-------------------------------------------------------------------------
    public init(
        ref: SampleRef
    ) {
        self.ref = ref
        print("Sample \(ref)")
    }
 
//    convenience init(_ xml: TreeNode)
//    {
//        assert(xml.value == "Sample")
//        self.init()
//    }
    
    private func handleError(_ error:SampleError) {
        print("Error: cannot load sample: \(error.localizedDescription)")
        self.error = error
    }
        //-------------------------------------------------------------------------
        //  iniitialize based on a new FCS File added
    public func setUp(core:CytegeistCoreAPI)
    {
        debug("in SetUp")
        
        guard let ref else {
            handleError(.noRef)
            return
        }
        
        Task {
            do {
                meta = try await core.loadSample(SampleRequest(ref, includeData: false)).getResult().meta
                btime = meta?.keywordLookup["$BTIM"] ?? ""
                print("Loaded metadata")
            } catch {
                handleError(.queryError(error))
            }
        }
        print("sample validity check")
    }
    
    private var _tree:AnalysisNode?
    public func getTree() -> AnalysisNode {
        if _tree == nil {
            _tree = SampleNode(self)
        }
        return _tree!
    }

 
}

