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
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.id = try container.decode(UUID.self, forKey: .id)
//        self.uri = try container.decodeIfPresent(String.self, forKey: .uri) ?? ""
////        self.file = try container.decodeIfPresent(FCSFile.self, forKey: .file) ?? .empty
//        self.sampleId = try container.decodeIfPresent(String.self, forKey: .sampleId) ?? ""
//        self.variety = try container.decode(String.self, forKey: .variety)
//        self.plantingDepth = try container.decodeIfPresent(Float.self, forKey: .plantingDepth)
//        self.daysToMaturity = try container.decode(Int.self, forKey: .daysToMaturity)
//        self.datePlanted = try container.decodeIfPresent(Date.self, forKey: .datePlanted)
//        self.harvestDate = try container.decodeIfPresent(Date.self, forKey: .harvestDate)
//        self.favorite = try container.decode(Bool.self, forKey: .favorite)
//        self.lastWateredOn = try container.decode(Date.self, forKey: .lastWateredOn)
//        self.wateringFrequency = try container.decodeIfPresent(Int.self, forKey: .wateringFrequency)
//        //        self.attributes = try container.decode([String : String].self, forKey: .attributes)
//        //        self.dimensions = try container.decode([CDimension].self, forKey: .dimensions)
//        //        self.matrix = try container.decode(CMatrix.self, forKey: .matrix)
//        //        self.membership = try container.decode([String : PValue].self, forKey: .membership)
//        //        self.validity = try container.decode(SampleValidityCheck.self, forKey: .validity)
//        //        self.tree = try container.decode(AnalysisTree.self, forKey: .tree)
//        self.imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
//        //        self.data = try container.decode(Data.self, forKey: .data)
//        //        self.fcsFile = try container.decode(FCSFile.self, forKey: .fcsFile)
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
//        assert(!fcsFile.meta.isEmpty)
//        assert(!fcsFile.data.isEmpty)
        
//        guard let keys = meta?.keywordLookup else {
//            print("No metadata for FCS file loaded")
//            return
//        }
        
//        attributes.merge(keys,  uniquingKeysWith: +)
        
//        debug("build dimension columns")
//        let nDims = Int(keys["$PAR"]!) ?? 0
//        if ( nDims > 0) {
//            print("\(nDims)")
//            for i in 1...nDims
//            {
//                let prefix = "$P\(i)"
//                let otherPrefix = "P\(i)"
//                let name = keys[prefix+"N"] ?? ""
//                let stain = keys[prefix+"S"] ?? ""
//                let display = keys[otherPrefix+"DISPLAY"] ?? ""
//                let bits = keys[prefix+"B"] ?? ""
//                let range = keys[prefix+"R"] ?? ""
//                print(prefix, name, stain, display, bits, range)
//                let dimension = CDimension( name: name, stain: stain,display:  display, bits: bits, range: range)
//                dimensions.append(dimension)
//            }
//        }
//        dimensions.filter({  $0.stain.count > 0 }).makeIterator().forEach { dim in
//            stained[dim.name] = dim.stain
//        }
   //       print(stained)
        

//        let data = fcsFile!.data?.parameterData
//        let eventData = data!.map { $0[0..<nDims] }
//            print("First \(nDims) data points:", eventData)
//
        
        
//        var eventData = fcsFile.data.unflattening(dim: width)
        
 
        print("sample validity check")
        
//        print("events: \(cellCount) X parms: \(nDims)  = \(fcsFile.data.count) ")
    }


  
    //---------------------------------------------------------
//    func readSpilloverMatrix(xml: TreeNode) -> CMatrix
//    {
//        var names = [String]()
//        var spillovers = [String : [String : Double]]()
//        if let parms = xml.findChild(value: "data-type:parameters")
//        {
//            for node in parms.children where node.value == "data-type:parameter"
//            {
//                if let s = node.attrib["data-type:name"]
//                {
//                    names.append(node.attrib[s] ?? "noVal")
//                }
//                else { print ("error in readSpilloverMatrix")}
//            }
//        }
//        if let spills = xml.findChild(value: "transforms:spillover")
//        {
//            if let parmName = spills.attrib["data-type:parameter"] {
//                var spilllist = [String: Double]()
//                for node in spills.children where node.value == "transforms:coefficient"
//                {
//                    if let parm = node.attrib["data-type:parameter"] {
//                        if let val = node.attrib["transforms:value"]  {
//                            spilllist[parm] =  Double(val)
//                        }
//                    }
//                }
//                spillovers[parmName] = spilllist
//            }
//        }
//        return CMatrix(dims: names, spillovers: spillovers)
//    }
//    
//    //---------------------------------------------------------
//    struct SampleValidityCheck : Codable
//    {
//        var timeSlices: String
//        var largeDeltaTimeCheck: Dictionary<String, String>
//        var eventRateConsistency: Dictionary<String, String>
//        var parameterCheck: [ParameterCheck]
//        
//        init() {
//            timeSlices = ""
//            largeDeltaTimeCheck = Dictionary<String, String>()
//            eventRateConsistency = Dictionary<String, String>()
//            parameterCheck = []
//        }
//        
//        init(xml: TreeNode) {
//            timeSlices = ""
//            largeDeltaTimeCheck = Dictionary<String, String>()
//            eventRateConsistency = Dictionary<String, String>()
//            parameterCheck = []
//        }
//    }
}
