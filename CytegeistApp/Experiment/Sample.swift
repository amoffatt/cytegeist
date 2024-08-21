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
  
  struct CDimension : Codable, Hashable
  {
      var attributes = [String : String]()
      var label = "unnamed parameter";
      var auto = true;
      var transform = 1

      var bits = "bits";
      var name = "unnamed";
      var stain = "stain";
      var display = "display";
      var range = "range";


      init (name: String )
      {
          self.name = name
      }
      
      init (name: String, stain: String, display: String, bits: String, range: String)
      {
          self.name = name
          self.stain = stain
          self.display = display
          self.bits = bits
          self.range = range
      }
      
     init(xml: TreeNode)
      {
          attributes.merge(xml.attrib, uniquingKeysWith: +)
          self.name = attributes["name"] ?? "NA"
          self.label = attributes["label"] ?? "NA"
          self.auto = attributes["auto"] == "1"
    }
     enum transfunction
      {
          case lin
          case log
          case biex
      }
      
      var negDecades = 0
      var width = -100
      var posDecades = 4.4771212547
      
      var min = 0
      var max = 300000
      var gain = "1"
      
      
      func hash(into hasher: inout Hasher) {
          ///        hasher.combine(x)
          ///         hasher.combine(y)
      }
      
      static func == (lhs: CDimension, rhs: CDimension) -> Bool {
          lhs.name == rhs.name;
      }
      
  }

//---------------------------------------------------------
//@Observable
public class Sample : Identifiable, Codable
{
    public var id: UUID
    var uri:String  = "n/a"  // do we need to keep this outside attributes
    var sampleId = ""
    var variety: String
    var plantingDepth: Float?
    var daysToMaturity: Int = 0
    var datePlanted:Date? = Date()
    var harvestDate:Date?  = Date()
    var favorite: Bool = false
    var lastWateredOn = Date()
    var wateringFrequency: Int?
    
    
    
        var attributes: [String: String] = [:]
        var dimensions = [CDimension]()
    //    var matrix = CMatrix()
    //    var membership =  [String : PValue]()
    //    var validity = SampleValidityCheck ()
    var tree = AnalysisNode()
    var imageURL: URL?
    var data = Data()
    @CodableIgnored
    @ObservationIgnored
    var fcsFile:FCSFile?
    var cellCount: Int = 0
 
    var tubeName:  String = ""
    var experimentName:  String = ""
    var date: String = ""
    var btime:  String = ""
    var filename:  String = ""
    var creator:  String = ""
    var apply:  String = ""
    var threshold:  String = ""
    var src:  String = ""
    var sys:  String = ""
    var cytometer:  String = ""
    var setup1:  String = "s"
    var stained : [String : String] = [:]       // dictionary of dimension names and stains
    
        //-------------------------------------------------------------------------
    //read from JSON
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.uri = try container.decodeIfPresent(String.self, forKey: .uri) ?? ""
//        self.file = try container.decodeIfPresent(FCSFile.self, forKey: .file) ?? .empty
        self.sampleId = try container.decodeIfPresent(String.self, forKey: .sampleId) ?? ""
        self.variety = try container.decode(String.self, forKey: .variety)
        self.plantingDepth = try container.decodeIfPresent(Float.self, forKey: .plantingDepth)
        self.daysToMaturity = try container.decode(Int.self, forKey: .daysToMaturity)
        self.datePlanted = try container.decodeIfPresent(Date.self, forKey: .datePlanted)
        self.harvestDate = try container.decodeIfPresent(Date.self, forKey: .harvestDate)
        self.favorite = try container.decode(Bool.self, forKey: .favorite)
        self.lastWateredOn = try container.decode(Date.self, forKey: .lastWateredOn)
        self.wateringFrequency = try container.decodeIfPresent(Int.self, forKey: .wateringFrequency)
        //        self.attributes = try container.decode([String : String].self, forKey: .attributes)
        //        self.dimensions = try container.decode([CDimension].self, forKey: .dimensions)
        //        self.matrix = try container.decode(CMatrix.self, forKey: .matrix)
        //        self.membership = try container.decode([String : PValue].self, forKey: .membership)
        //        self.validity = try container.decode(SampleValidityCheck.self, forKey: .validity)
        //        self.tree = try container.decode(AnalysisTree.self, forKey: .tree)
        self.imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        //        self.data = try container.decode(Data.self, forKey: .data)
        //        self.fcsFile = try container.decode(FCSFile.self, forKey: .fcsFile)
    }
    
        //-------------------------------------------------------------------------
   init(
        id: UUID,
        variety: String,
        plantingDepth: Float? = nil,
        daysToMaturity: Int = 0,
        datePlanted: Date = Date(),
        favorite: Bool = false,
        lastWateredOn: Date = Date(),
        wateringFrequency: Int? = 5,
        fcsFile: FCSFile? = nil
    ) {
        self.id = id
        self.variety = variety
        self.plantingDepth = plantingDepth
        self.daysToMaturity = daysToMaturity
        self.datePlanted = datePlanted
        self.favorite = favorite
        self.lastWateredOn = lastWateredOn
        self.wateringFrequency = wateringFrequency
        self.fcsFile = fcsFile
        print("Sample \(variety) ")
    }
 
    convenience init()
    {
        self.init(id: UUID(), variety: "New Sample")
    }
    
    convenience init(fcs: FCSFile)
    {
        self.init(id: UUID(), variety: "New Sample From FCS")
        fcsFile = fcs
    }
    
    convenience init(_ xml: TreeNode)
    {
        assert(xml.value == "Sample")
        self.init()
        variety = "NEW-SAMPLE"
        wateringFrequency = 2
        plantingDepth = 1.8
            //}
    }
        //-------------------------------------------------------------------------
        //  iniitialize based on a new FCS File added
    func setUp()
    {
        debug("in SetUp")
//        assert(!fcsFile.meta.isEmpty)
//        assert(!fcsFile.data.isEmpty)
        
        let keys = fcsFile!.meta.keywordLookup
        
        attributes.merge(keys,  uniquingKeysWith: +)
        
        cellCount = Int(keys["$TOT"]! ) ?? 1000
        tubeName = keys["TUBE NAME"] ?? " "
        experimentName = keys["EXPERIMENT NAME"] ?? " "
        date = keys["$DATE"] ?? ""
        btime = keys["$BTIM"] ?? " "
        filename = keys["$FIL"] ?? " "
        creator = keys["CREATOR"] ?? " "
        apply = keys["APPLY COMPENSATION"] ?? " "
        setup1 = keys["CST SETUP STATUS"] ?? " "
        threshold = keys["THRESHOLD"] ?? " "
        src = keys["$SRC"] ?? " "
        sys = keys["$SYS"] ?? " "
        cytometer = keys["$CYT"] ?? " "

        debug("build dimension columns")
        let nDims = Int(keys["$PAR"]!) ?? 0
        if ( nDims > 0) {
            print("\(nDims)")
            for i in 1...nDims
            {
                let prefix = "$P\(i)"
                let otherPrefix = "P\(i)"
                let name = keys[prefix+"N"] ?? ""
                let stain = keys[prefix+"S"] ?? ""
                let display = keys[otherPrefix+"DISPLAY"] ?? ""
                let bits = keys[prefix+"B"] ?? ""
                let range = keys[prefix+"R"] ?? ""
                print(prefix, name, stain, display, bits, range)
                let dimension = CDimension( name: name, stain: stain,display:  display, bits: bits, range: range)
                dimensions.append(dimension)
            }
        }
        dimensions.filter({  $0.stain.count > 0 }).makeIterator().forEach { dim in
            stained[dim.name] = dim.stain
        }
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
