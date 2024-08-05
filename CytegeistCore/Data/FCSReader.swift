//
//  FCSReader.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/13/24.
//

import Foundation

public typealias FCSParameterValueReader = (DataBufferReader) throws -> Float

public struct FCSParameter {
    public static func displayName(_ name:String, _ stain:String) -> String {
        if name == stain {
            return name
        }
        if stain.isEmpty {
            return name
        }
        return "\(name) : \(stain)"
    }
    
    public let name: String
    public let stain: String
    public let displayName: String
    public let bits: Int
    public var bytes: Int { (bits + 7) / 8 }
    public let range: Double
    public let filter: String
    public let normalizer: AxisNormalizer
    public let valueReader: FCSParameterValueReader
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

public enum FCSByteOrder: String {
    case bigEndian = "4,3,2,1"
    case littleEndian = "1,2,3,4"
}

public enum FCSDataType: String {
    case integer = "I"
    case float = "F"
    case double = "D"
    case ascii = "A"
    case unicode = "U"
}


public struct StringField : Identifiable {
    public var id:String { name }
    
    public let name:String
    public let value:String
    public init(_ name: String, _ value: String) {
        self.name = name
        self.value = value
    }
}


public struct FCSMetadata {
    
    public private(set) var keywords: [StringField] = []
    public private(set) var keywordLookup: [String:String] = [:]

    public var eventCount: Int = 0
    public var dataType: FCSDataType = .integer
    public var date: String = ""
    public var byteOrder: FCSByteOrder?
    public var system:String = ""
    public var cytometer: String = ""

    
    public var _parameters: [FCSParameter]?
    public var parameterLookup:[String:Int] = [:]
    
    public var parameters: [FCSParameter]? {
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

public struct EventData: Identifiable {
    public let id: Int
    public let values: [Float]
}

public struct SampleNumericData: RandomAccessCollection {
    public typealias Element = EventData
    
    public typealias Index = Int
    
    public typealias SubSequence = SampleNumericData
    
    public typealias Indices = Range<Int>
    
    public var startIndex: Int {
        return parameterData.isEmpty ? 0 : parameterData[0].startIndex
    }

    public var endIndex: Int {
        return parameterData.isEmpty ? 0 : parameterData[0].endIndex
    }
    
    public var count:Int {
        parameterData.isEmpty ? 0 : parameterData[0].count
    }

    // Subscript to access elements
    public subscript(position: Int) -> EventData {
        precondition(position >= startIndex && position < endIndex, "Index out of bounds")
        let values = parameterData.map { $0[position] }
        return EventData(id: position, values: values)
    }
    
    public subscript(bounds: Range<Int>) -> SampleNumericData {
        let slicedData = parameterData.map { Array($0[bounds]) }
        return SampleNumericData(data: slicedData)
    }
    
    public func index(after i: Int) -> Int {
        return i + 1
    }

    public func index(before i: Int) -> Int {
        return i - 1
    }
    
    
    public let parameterData:[[Float]]
//    public let parameterNames:[String]
    
    init(data:[[Float]]) {
        parameterData = data
    }
    
}

public struct FCSFile {
    public let meta:FCSMetadata
    public let data:SampleNumericData?
    
    public func parameter(named:String) -> (meta:FCSParameter, data:[Float])? {
        guard let data,
              let parameters = meta.parameters,
              let index = meta.parameterLookup[named] else {
            return nil
        }
        return (parameters[index], data.parameterData[index])
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
        fcs.date = keywords["$DATE"].nonNil
        fcs.dataType = FCSDataType(rawValue: keywords["$DATATYPE"].nonNil)!
        fcs.byteOrder = FCSByteOrder(rawValue: keywords["$BYTEORD"].nonNil)
        
        
        // Parse parameters
        let parameterCount = Int(keywords["$PAR"]!)!
        let parameters:[FCSParameter] = try (1...parameterCount).map { n in
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
    
    private func readEventData(dataSegment:Data, meta:FCSMetadata) throws -> SampleNumericData {
        let eventCount = meta.eventCount
        let parameters = meta.parameters!
        let parameterCount = parameters.count
        
        var parameterDataArray = parameters.map { p in
            Array(repeating: Float(0), count: meta.eventCount)
        }
        let valueReaderArray = parameters.map { p in p.valueReader }
        
        let dataReader = DataBufferReader(data:dataSegment, bigEndian: meta.byteOrder == .bigEndian)
//        let dataReader = DataBufferReader(data:data[1..<200], bigEndian: fcsFile.byteOrder == .bigEndian)

        
        for eventIndex in 0..<eventCount {
            for i in 0..<parameterCount {
                parameterDataArray[i][eventIndex] = try valueReaderArray[i](dataReader)
            }
        }
        
        return try SampleNumericData(data: parameterDataArray)
    }
    
    private func readParameterInfo(_ metadata:[String: String], n:Int, dataType:FCSDataType) throws -> FCSParameter {
        let name = metadata["$P\(n)N"]?.trim() ?? "P\(n)"
        let stain = metadata["$P\(n)S"].nonNil.trim()
        let bits = Int(metadata["$P\(n)B"]!)!
        let range = Double(metadata["$P\(n)R"]!)!
        let filter = metadata["$P\(n)F"].nonNil
        let displayName = FCSParameter.displayName(name, stain)
        let normalizer = LinearAxisNormalizer(min:0, max:Float(range))
        let valueReader = try createParameterValueReader(dataType: dataType, bits: bits)
        
        return FCSParameter(name: name, stain: stain, displayName: displayName,
                                bits: bits, range: range, filter: filter,
                                normalizer: normalizer,
                                valueReader: valueReader
                                )
    }
    
    private func error(_ description:String) -> Error {
        DataReaderError("FCSReaderError: \(description)")
    }
    
    private func createParameterValueReader(dataType:FCSDataType, bits:Int) throws -> FCSParameterValueReader {
        switch dataType {
            case .integer:
                try DataBufferReader.validateIntType(bits: bits)
                return { reader in Float(try reader.readUInt(bits:bits)) }
            case .float, .double:
                try DataBufferReader.validateFloatType(bits: bits)
                return { reader in try reader.readFloat(bits:bits) }
            case .ascii, .unicode:
                throw error("Unsupported data type \(dataType)")
        }
    }
    
    private func readHeader(_ data:Data) throws -> FCSHeader {
        guard data.endIndex > FCSHeader.length else {
            throw error("File length too short for FCS header: \(data.endIndex) bytes")
        }
        
        var textRange = self.readHeaderField(data, 0)...self.readHeaderField(data, 1)
        
        var dataRange = self.readHeaderField(data, 2)...self.readHeaderField(data, 3)

        var analysisRange = self.readHeaderField(data, 4)...self.readHeaderField(data, 5)
        
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


