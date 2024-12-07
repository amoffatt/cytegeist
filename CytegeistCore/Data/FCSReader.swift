//
//  FCSReader.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/13/24.
//

import Foundation
import CoreGraphics
import CytegeistLibrary

public typealias FCSParameterValueReader = (DataBufferReader) throws -> ValueType

public struct CDimension : Identifiable, Hashable, Codable {
    public var id: String { name }
    
    
    public static func displayName(_ name:String, _ stain:String) -> String {
        if name == stain {      return name     }
        if stain.isEmpty {      return name     }
        return "\(name) : \(stain)"
    }
    
    public let name: String
    public let stain: String
    public let shortName: String
    public let displayName: String
    public let bits: Int
    public var bytes: Int { (bits + 7) / 8 }
    public let range: Double
    public let filter: String
    public let displayInfo: String
    public let normalizer: AxisNormalizer
    
    
    public let valueReader: FCSParameterValueReader
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    public static func == (lhs: CDimension, rhs: CDimension) -> Bool {
        lhs.name == rhs.name
    }
    
    public init(name: String, stain: String, displayName: String,
                bits: Int, range: Double, filter: String,
                displayInfo: String, normalizer: AxisNormalizer,
                valueReader: @escaping FCSParameterValueReader) {
        self.name = name
        self.shortName = name
        self.stain = stain
        self.displayName = displayName
        self.bits = bits
        self.range = range
        self.filter = filter
        self.displayInfo = displayInfo
        self.normalizer = normalizer
        self.valueReader = valueReader
    }
    
    public init(from decoder: any Decoder) throws {
        fatalError()
    }
    
    public func encode(to encoder: any Encoder) throws {
        fatalError()
    }

}

//public class FCSParameter {
//    public let info: FCSParameterInfo
//    public var data: [Float] = []
//    
//    init(_ info:FCSParameterInfo, data:[Float]) {
//        self.info = info
//        self.data = data
//    }
//}

public enum FCSByteOrder: String, Hashable, Codable {
    case bigEndian = "4,3,2,1"
    case littleEndian = "1,2,3,4"
}

public enum FCSDataType: String, Hashable, Codable {
    case integer = "I"
    case float = "F"
    case double = "D"
    case ascii = "A"
    case unicode = "U"
}


public struct StringField : Identifiable, Hashable, Codable {
    public var id:String { name }
    
    public let name:String
    public let value:String
    public init(_ name: String, _ value: String) {
        self.name = name
        self.value = value
    }
}


public struct FCSMetadata: Hashable, Codable {
    
    public private(set) var keywords: [StringField] = []
    public private(set) var keywordLookup: [String:String] = [:]

    public var eventCount: Int = 0
    public var dataType: FCSDataType = .integer
    public var date: String = ""
    public var byteOrder: FCSByteOrder?
    public var system:String = ""
    public var cytometer: String = ""
    public var comp: String = ""

    
    public var _parameters: [CDimension]?
    public var parameterLookup:[String:Int] = [:]
    
    
    public var parameters: [CDimension]? {
        get { _parameters }
        set {
            _parameters = newValue
            parameterLookup = newValue == nil
            ? [:]
            : .init(uniqueKeysWithValues: newValue!.enumerated().map { i, parameter in
                (parameter.name, i)
            })
        }
    }
    
    public func parameter(named: String?) -> CDimension? {
        if let named, let parameters, let index = parameterLookup[named] {
            return parameters.get(index: index)
        }
        return nil
    }

    mutating public func addKeyword(_ name:String, _ value:String) {
        guard keywordLookup[name] == nil else {
            print("Keyword '\(name)' already found in file')")
            return
        }
        keywords.append(.init(name, value))
        keywordLookup[name] = value
    }

//    public var parameter
}

enum EventDataError : Error {
    case inconsistentDimLengths
}

public typealias ValueType = Double
public typealias CPoint = CGPoint   // CGPoint, and CGRect use Double values
public typealias CRect = CGRect

extension CPoint : Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combineMany(x, y)
    }
}

extension CRect : Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combineMany(origin, size.width, size.height)
    }
}


public struct EventData: Identifiable {
    public let id: Int
    public let values: [ValueType]
}


public struct EventDataTable: BackedRandomAccessCollection {
    
    public typealias Element = EventData
    public typealias SubSequence = EventDataTable
    
    public var _indexBacking:[ValueType] { data.first ?? [] }

    // Subscript to access elements
    public subscript(position: Int) -> EventData {
        precondition(position >= startIndex && position < endIndex, "Index out of bounds")
        let values = data.map { $0[position] }
        return EventData(id: position, values: values)
    }
    
    public subscript(bounds: Range<Int>) -> EventDataTable {
        let slicedData = data.map { Array($0[bounds]) }
        return try! EventDataTable(data: slicedData)
    }
    
    
    public let data:[[ValueType]]
//    public let parameterNames:[String]
    
    init(data:[[Double]]) throws {
        self.data = data
        
        if !data.isEmpty {
            let length = data[0].count
            
            if !data.allSatisfy({ $0.count == length }) {
                throw EventDataError.inconsistentDimLengths
            }
        }
    }
    
    public func columns(_ indices:[Int]) throws -> EventDataTable {
        return try .init(data: indices.map { data[$0] })
    }
    
}

public struct FCSParameterData {
    public let meta:CDimension
    public let data:[ValueType]
}

public protocol CPopulationData {
    var meta:FCSMetadata { get }
    var data:EventDataTable? { get }
    var count:Double { get }
    func probability(of index: Int) -> PValue
    var probabilities:[PValue]? { get }
}

public extension CPopulationData {
    
    func parameter(named:String) -> FCSParameterData? {
        guard let data,
              let parameters = meta.parameters,
              let index = meta.parameterLookup[named] else {
            return nil
        }
        return .init(meta:parameters[index], data:data.data[index])
    }
    
    func data(parameterNames:[String]) throws -> EventDataTable? {
        guard let data else {
            return nil
        }
        let indices = parameterNames.map { meta.parameterLookup[$0] }
        if !indices.allSatisfy({ $0 != nil }) {
            return nil
        }
        return try data.columns(indices.map { $0! })
    }

    
    
    func multiply(filterDims: [String], filter:(EventData) -> PValue) throws -> CPopulationData {
        guard let filterData = try self.data(parameterNames: filterDims) else {
            throw APIError.noDataAvailable
        }
        
        var probabilities = Array(repeating: PValue.zero, count: data?.count ?? 0)
        for i in 0..<probabilities.count {
            let event = filterData[i]
            probabilities[i] = .init(probability(of: i).p * filter(event).p)
        }
        return PopulationData(meta: meta, data: data, probabilities: probabilities)
    }
}

public struct FCSFile : CPopulationData {
    
    public let meta:FCSMetadata
    public let data:EventDataTable?
    
    public var count: Double { Double(data?.count ?? 0)}

    public func probability(of index: Int) -> PValue {
        .init(1.0)
    }
    
    public var probabilities: [PValue]? { nil }
}

public struct PopulationData : CPopulationData {
    public let meta:FCSMetadata
    public let data:EventDataTable?
    public let count:Double
    private let _probabilities: [PValue]
    public var probabilities: [PValue]? { _probabilities }
    
    init(meta: FCSMetadata, data: EventDataTable?, probabilities: [PValue]) {
        self.meta = meta
        self.data = data
        self._probabilities = probabilities
        self.count = probabilities.map { $0.p }.sum()
    }
    
    public func probability(of index: Int) -> PValue {
        _probabilities[index]
    }
}



public struct FCSHeader {
    public static let length = 58
    
    public var format: String
    public var textRange: ClosedRange<Int>
    public var dataRange: ClosedRange<Int>
    public var analysisRange: ClosedRange<Int>
}

public struct DataReaderError : Error {
    public let message: String
    public init(_ message:String) {
        self.message = message
    }
}

public class FCSReader {
    public init() {
        // AM DEBUGGING
//        ExceptionCatcher.catchException {}
    }
    
    public func readFCSFile(at url: URL, includeData:Bool = true) throws -> FCSFile {
        let data = try Data(contentsOf: url)
        var fcs = FCSMetadata()
        
        var header = try self.readHeader(data)
        guard header.format.hasPrefix("FCS") else {
            throw self.error("Invalid FCS file format '\(header.format)'")
        }
        

//        // Parse text segment
//        let textStart = Int(header[10..<18])!
//        let textEnd = Int(header[18..<26])!
        
        guard header.textRange.within(data.indices) else {
            throw error("File content too short for specified text metadata: \(data.endIndex) < \(header.textRange.upperBound) bytes")
        }
        
        let textSegment = data[header.textRange]
        let textString = textSegment.string(.ascii)
        
        guard let textString else {
            throw self.error("No text data in file")
        }
        
        let separator = String(textString.first!)
        
        
        
        let keyValuePairs = textString.splitWithDoubleEscaping(separator: separator)
        for i in stride(from: 0, to: keyValuePairs.count - 1, by: 2) {
            let key = keyValuePairs[i].trimmingCharacters(in: .whitespaces)
            let value = keyValuePairs[i + 1].trimmingCharacters(in: .whitespaces)
            fcs.addKeyword(key, value)
        }
        let keywords = fcs.keywordLookup
        
        
        var dataRange = header.dataRange
        if dataRange.upperBound == 0 {
            dataRange = dataRange.update(upperBound: Int(keywords["$ENDDATA"].nonNil))
        }
        if dataRange.lowerBound == 0 {
            dataRange = dataRange.update(lowerBound: Int(keywords["$BEGINDATA"].nonNil))
        }
        header.dataRange = dataRange

        // Read data segment
        guard dataRange.within(data.indices) else {
            throw error("Data range specified in FCS header is outside file bounds \(dataRange) is outside range of \(data.indices)")
        }
        let dataSegment = data[dataRange]
        
        // Parse data based on parameters
//        var byteOffset = 0
//        let eventCount = dataSegment.count / (fcsFile.parameters.reduce(0) { $0 + ($1.bits + 7) / 8 })
        let eventCount = Int(keywords["$TOT"]!)!
        fcs.eventCount = eventCount
        fcs.system = keywords["$SYS"]!
        fcs.cytometer = keywords["$CYT"].nonNil
        fcs.comp = keywords["$COMP"].nonNil
        fcs.date = keywords["$DATE"].nonNil
        fcs.dataType = FCSDataType(rawValue: keywords["$DATATYPE"].nonNil)!
        fcs.byteOrder = FCSByteOrder(rawValue: keywords["$BYTEORD"].nonNil)
        
        
        // Parse parameters
        let parameterCount = Int(keywords["$PAR"]!)!
        let parameters:[CDimension] = try (1...parameterCount).map { n in
            try self.readParameterInfo(keywords, n:n, dataType: fcs.dataType)
        }
        fcs.parameters = parameters

        
        let parameterBits = parameters.map { $0.bits }
        
        let bytesPerEvent = parameterBits.sum() / 8
        
        let totalBytes = fcs.eventCount * bytesPerEvent
        
        let dataLength = dataRange.count
        guard totalBytes == dataLength else {
            throw self.error("Data segment size (\(dataLength)) doesn't match expected size (\(totalBytes))")
        }
        
        
        return FCSFile(
            meta: fcs,
            data: includeData ? try readEventData(dataSegment: dataSegment, meta: fcs) : nil)
    }
    
    private func readEventData(dataSegment:Data, meta:FCSMetadata) throws -> EventDataTable {
        let eventCount = meta.eventCount
        let parameters = meta.parameters!
        let parameterCount = parameters.count
        
        var parameterDataArray = parameters.map { p in
            Array(repeating: ValueType(0), count: meta.eventCount)
        }
        let valueReaderArray = parameters.map { p in p.valueReader }
        
        let dataReader = DataBufferReader(data:dataSegment, bigEndian: meta.byteOrder == .bigEndian)
//        let dataReader = DataBufferReader(data:data[1..<200], bigEndian: fcsFile.byteOrder == .bigEndian)

        
        for eventIndex in 0..<eventCount {
            for i in 0..<parameterCount {
                if i % 10000 == 0 {
                    try Task.checkCancellation()
                }
                parameterDataArray[i][eventIndex] = try valueReaderArray[i](dataReader)
            }
        }
        
        return try EventDataTable(data: parameterDataArray)
    }
    
    private func readParameterInfo(_ metadata:[String: String], n:Int, dataType:FCSDataType) throws -> CDimension {
        let name = metadata["$P\(n)N"]?.trim() ?? "P\(n)"
        let stain = metadata["$P\(n)S"].nonNil.trim()
        let bits = Int(metadata["$P\(n)B"]!)!
        let range = Double(metadata["$P\(n)R"]!)!
        let filter = metadata["$P\(n)F"].nonNil
        var displayInfo = metadata["P\(n)DISPLAY"].nonNil
        if displayInfo.isEmpty {
            displayInfo = metadata["$P\(n)D"].nonNil
        }
        let displayName = CDimension.displayName(name, stain)
        let normalizer = createParameterNormalizer(max: range, displayInfo: displayInfo)
        let valueReader = try createParameterValueReader(dataType: dataType, bits: bits)
        
        return CDimension(name: name, stain: stain, displayName: displayName,
                                bits: bits, range: range, filter: filter,
                                displayInfo: displayInfo,
                                normalizer: normalizer,
                                valueReader: valueReader
                                )
    }
    
    private func error(_ description:String) -> Error {
        DataReaderError("FCSReaderError: \(description)")
    }
    
    private func createParameterNormalizer(max:Double, displayInfo:String) -> AxisNormalizer {
//        if displayinfo == "log" && max > 1 {
//            return .log(minval: 1, maxval: max)
//        }
        let split = displayInfo.split(separator: ",").map { String($0)}
        let type = split.first.nonNil.lowercased()
        
        if type.starts(with: "log") && max > 1 {
            var minVal = 1.0
            var maxVal = max
            if split.count == 3 {
                minVal = Double(split[2]) ?? minVal
                if let decades = Double(split[1]) {
                    maxVal = minVal * pow(10, decades)
                }
            }
            return .log(minVal: minVal, maxVal: maxVal)
        }

        
        return .linear(minVal: 0, maxVal: max)
    }
    
    private func createParameterValueReader(dataType:FCSDataType, bits:Int) throws -> FCSParameterValueReader {
        switch dataType {
            case .integer:
                try DataBufferReader.validateIntType(bits: bits)
                return { reader in ValueType(try reader.readUInt(bits:bits)) }
            case .float, .double:
                try DataBufferReader.validateFloatType(bits: bits)
                return { reader in try ValueType(reader.readFloat(bits:bits)) }
            case .ascii, .unicode:
                throw error("Unsupported data type \(dataType)")
        }
    }
    
    private func readHeader(_ data:Data) throws -> FCSHeader {
        guard data.endIndex > FCSHeader.length else {
            throw error("File length too short for FCS header: \(data.endIndex) bytes")
        }
        
        var textRange = self.readHeaderField(data, 0)...self.readHeaderField(data, 1)
        
        let dataRange = self.readHeaderField(data, 2)...self.readHeaderField(data, 3)

        let analysisRange = self.readHeaderField(data, 4)...self.readHeaderField(data, 5)
        
        // If text end is written as the same value as data start by cytometer, correct this
        // e.g http://flowrepository.org/experiments/2241/download_ziped_files
        if textRange.upperBound == dataRange.lowerBound {
            textRange = .init(uncheckedBounds: (textRange.lowerBound, textRange.upperBound - 1))
        }
        
        if !analysisRange.isEmpty {
            print("** Analysis section is not empty. Not currently read")
        }
        
        
        return FCSHeader(format: data[0..<6].string(.ascii).nonNil,
                         textRange:textRange, dataRange:dataRange, analysisRange:analysisRange)

    }
    
    private func readHeaderField(_ data:Data, _ index:Int) -> Int {
        let startOffset = 10 + index * 8
        let fieldBytes = data[startOffset..<(startOffset+8)]
        let fieldString = fieldBytes.string(.ascii)!.trim()
        return Int(fieldString) ?? 0
    }
    
}


