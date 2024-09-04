////
////  Cytometer.swift
////  filereader
////
////  Created by Adam Treister on 7/19/24.
////
//
////PROBABLY SHOULD BE CLEANED AND REPLACED WITH DICTIONARIES, MOVED TO EXPERIMENT
//
//import Foundation
//
//struct Cytometer
//{
//    var name = "DIVA"
//    var cyt = "FACSCantoII"
//    var useFCS3 = "1"
//    var extraNegs = "0"
//    var widthBasis = "-100"
//    var linMin = 0, logMin = 3
//    var linMax = 262144,  logMax = 262144
//    var linearRescale = 1.0, logRescale = 1.0
//    var linFromKW = 1.0, logFromKW = 1.0
//    var useGain = false, useTransform = false
//    
//    var transformType = "BIEX"
//    var manufacturer = "BD"
//    var serialnumber = "123"
//    var homepage = ""
//    var icon = "1"
//    
//    var linear = [Dimension]()
//    var filters =  [Dimension]()
//    
//    
//    init(xml : XMLNode)
//    {
//        print ("XML parsing of Cytometer")
//        self.name = ""
//        self.cyt = ""
//        self.useFCS3 = "1"
//        self.extraNegs = "0"
//        self.widthBasis = "-100"
//        self.linMin = 0
//        self.logMin = 1
//        self.linMax = 262144
//        self.logMax = 262144
//        self.linearRescale = 1
//        self.logRescale = 1.0
//        self.linFromKW = 1.0
//        self.logFromKW = 1.0
//        self.useGain = false
//        self.useTransform = false
//        self.transformType = ""
//        self.manufacturer = ""
//        self.serialnumber = ""
//        self.homepage = ""
//        self.icon = ""
//    }
//    
//    
//    init(name: String = "DIVA", cyt: String = "FACSCantoII",
//         useFCS3: String = "1", extraNegs: String = "0", widthBasis: String = "-100",
//         linMin: Int = 0, logMin: Int = 3, linMax: Int = 262144, logMax: Int = 262144,
//         linearRescale: Double = 1.0, logRescale: Double = 1.0, linFromKW: Double = 1.0, logFromKW: Double = 1.0,
//         useGain: Bool = false, useTransform: Bool = false, transformType: String = "BIEX", manufacturer: String = "BD", serialnumber: String = "123", homepage: String = "", icon: String = "1", linear: [Dimension], filters: [Dimension]) {
//        self.name = name
//        self.cyt = cyt
//        self.useFCS3 = useFCS3
//        self.extraNegs = extraNegs
//        self.widthBasis = widthBasis
//        self.linMin = linMin
//        self.logMin = logMin
//        self.linMax = linMax
//        self.logMax = logMax
//        self.linearRescale = linearRescale
//        self.logRescale = logRescale
//        self.linFromKW = linFromKW
//        self.logFromKW = logFromKW
//        self.useGain = useGain
////        self.useTransform = useTransform
//        self.transformType = transformType
//        self.manufacturer = manufacturer
//        self.serialnumber = serialnumber
//        self.homepage = homepage
//        self.icon = icon
//        self.linear = linear
//        self.filters = filters
//    }
//    
//}
