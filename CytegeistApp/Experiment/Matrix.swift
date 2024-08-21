//
//  Matrix.swift
//  HousingData
//
//  Created by Adam Treister on 7/9/24.
//  PROBABLY NOT NEEDED IN  CYTEGEIST:  Matrices are usually included in FCS files

import Foundation
import CytegeistLibrary


//---------------------------------------------------------
    struct CMatrix : Codable
    {
        var attrib = [String : String]()
        var dimensions = [CDimension]()
        var spillovers = [String : [String : Double]]()
       
        init()
        {
        }
        init(dims: [String], spillovers: [String : [String : Double]])
        {
        }
        init(xml: TreeNode)
        {
        }
    }
struct ParameterCheck : Codable
    {
        var medians = [Double]()
        var kineticsThresholdCheck = ""
        var kinetics = ""

    }
//    func parseSampleValidity(sv: TreeNode) -> SampleValidityCheck
//    {
//        assert(sv.value == "SampleValidity")
//        return SampleValidityCheck(xml: sv)
//    }


//---------------------------------------------------------
public struct MatrixReader
{
    var name = ""
    var spillover = SpillOverMatrix()
    init(name: String = "", spillover: SpillOverMatrix) {
        self.name = name
        self.spillover = spillover
    }
    init(xmlTree: TreeNode ) {
    }
}

//--------------------------------------------------------
public struct SpilloverLine
{
    var dim: CDimension
    var values: [CDimension : Float]
 }


public struct SpillOverMatrix
{
    var prefix="Comp-"
    var name="Acquisition-defined"
    var editable="0"
    var color="#c0c0c0"
    var version="Cytegeist.001"
    var status="FINALIZED"
    var transformsId="0ab9"
    var suffix=""
    var lines = [SpilloverLine]()
}
