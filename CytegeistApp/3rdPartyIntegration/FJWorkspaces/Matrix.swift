//
//  Matrix.swift
//  HousingData
//
//  Created by Adam Treister on 7/9/24.
//  PROBABLY NOT NEEDED IN  CYTEGEIST:  Matrices are usually included in FCS files

import Foundation
import CytegeistCore
import CytegeistLibrary


//---------------------------------------------------------
//    struct CMatrix : Codable
//    {
//        var attrib = [String : String]()
//        var dimensions = [CDimension]()
//        var spillovers = [String : [String : Double]]()
//       
//        init()
//        {
//        }
//        init(dims: [String], spillovers: [String : [String : Double]])
//        {
//        }
//        init(xml: TreeNode)
//        {
//        }
//    }
//struct ParameterCheck : Codable
//    {
//        var medians = [Double]()
//        var kineticsThresholdCheck = ""
//        var kinetics = ""
//
//    }
//    func parseSampleValidity(sv: TreeNode) -> SampleValidityCheck
//    {
//        assert(sv.value == "SampleValidity")
//        return SampleValidityCheck(xml: sv)
//    }

//
////---------------------------------------------------------
//public struct MatrixReader
//{
//    var name = ""
//    var spillover = SpillOverMatrix()
//    init(name: String = "", spillover: SpillOverMatrix) {
//        self.name = name
//        self.spillover = spillover
//    }
//    init(xmlTree: TreeNode ) {
//    }
//}
//
////--------------------------------------------------------
//public struct SpilloverLine
//{
//    var dim: CDimension
//    var values: [CDimension : Float]
// }
//
//
//public struct SpillOverMatrix
//{
//    var prefix="Comp-"
//    var name="Acquisition-defined"
//    var editable="0"
//    var color="#c0c0c0"
//    var version="Cytegeist.001"
//    var status="FINALIZED"
//    var transformsId="0ab9"
//    var suffix=""
//    var lines = [SpilloverLine]()
//}
//




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



    //        print("events: \(cellCount) X parms: \(nDims)  = \(fcsFile.data.count) ")





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


    //        var columns : [TableColumn]     // the layout of the workspace window

    //    var _cytometers: [Cytometer]     // ignore
    //    var _matrices: [Matrix]          // ignore
    //    var _exports: [String]           // ignore
    //    var _scripts: [String]          // ignore
    //    var _history: [String]          // ignore
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

//
//CGROUP
//
//init(fjxml: TreeNode)
//{
//    attributes.merge(fjxml.attrib, uniquingKeysWith: +)
//    if let grop = fjxml.findChild(value: "Group")
//    {
//        for node in grop.children where node.value == "Criteria"
//        {
//            criteria.append(Criterion(fjxml: node))
//        }
//        print ("Group Criteria: " , criteria.count)
//    }
//    if let grph = fjxml.findChild(value: "Graph")
//    {
//        graph = ChartDef(fjxml:grph)
//        print ("Graph: " , grph.value)
//    }
//}
