//
//  Sample.swift
//  filereader
//
//  Created by Adam Treister on 7/19/24.
//

import Foundation
import CytegeistLibrary
import CytegeistCore


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
    var tree = AnalysisNode()
    var imageURL: URL?
    var meta:FCSMetadata?
    
//    var keywords:AttributeStore { meta?.keywordLookup ?? [:] }
    subscript(_ keyword:String) -> String { (meta?.keywordLookup[keyword]).nonNil }

    var eventCount: Int { meta?.eventCount ?? 0 }
 
    var tubeName: String { self["TUBE NAME"] }
    var experimentName:  String { self["EXPERIMENT NAME"] }
    var date: String { self["$DATE"] }
    var btime:  String = ""//{ meta?.keywordLookup["$BTIM"] ?? "" }
    var filename:  String { self["$FIL"] }
    var creator:  String { self["CREATOR"] }
    var apply:  String { self["APPLY COMPENSATION"] }
    var threshold:  String { self["THRESHOLD"] }
    var src:  String { self["$SRC"] }
    var sys:  String { self["$SYS"] }
    var cytometer:  String { self["$CYT"] }
    var setup1:  String { self["CST SETUP STATUS"] }


        //-------------------------------------------------------------------------
    //read from JSON
    
    public required init(from decoder: any Decoder) throws {
        fatalError("AM: Implement decoding")
}
    
        //-------------------------------------------------------------------------
   init(
//        id: UUID,
        ref: SampleRef
    ) {
//        self.id = id
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
    func setUp(core:CytegeistCoreAPI)
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

 
}
