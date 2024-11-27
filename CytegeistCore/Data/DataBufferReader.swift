//
//  DataBufferReader.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/26/24.
//

import Foundation


public class DataBufferReader {
    
    public static func validateFloatType(bits:Int) throws {
        if bits != 32 {
            throw DataReaderError("Unsupported floating point value size (\(bits) != 32)")
        }
    }
    
    public static func validateIntType(bits:Int) throws {
        if bits % 8 != 0 {
            throw DataReaderError("Unsupported integer value size (\(bits) bits does not align to byte boundary)")
        }
        
        if bits > 32 {
            throw DataReaderError("Unsupported integer value size (\(bits) > 32 bits)")
        }
    }
    
    let data:Data
    var byteOffset: Int
    let bigEndian: Bool
    
    var buffer:UnsafeMutableRawBufferPointer
    
    
    public init(data: Data, byteOffset: Int = 0, bigEndian: Bool = false) {
        self.data = data
        self.byteOffset = byteOffset
        self.bigEndian = bigEndian
        self.buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: MemoryLayout<UInt8>.alignment)
//        self.buffer.withUnsafeBytes(<#T##body: (UnsafeRawBufferPointer) throws -> R##(UnsafeRawBufferPointer) throws -> R#>)
    }
    
    deinit {
        buffer.deallocate()
    }
    
    public func readUInt(bits:Int) throws -> UInt32 {
        readBytes(bitCount: bits)
        let result = buffer.load(fromByteOffset: 0, as: UInt32.self)
        return result
    }
    
    public func readFloat(bits:Int) throws -> Float {
        
//        var result:Float = buffer.load(from)
        readBytes(bitCount: bits)
        let result = buffer.load(fromByteOffset: 0, as: Float32.self)
        return result
//        buffer.withUnsafeMutableBytes {
//            self.copyBytes(from: data, offsetBytes: offset, bitCount: valueBits, to: $0)
//            result = $0.load(fromByteOffset: 0, as: Float.self)
//        }
        
        
        
    }
    
    private func readBytes(bitCount: Int) {
        let byteCount = bitCount / 8
        memset(buffer.baseAddress, 0, 4)
        let start = (byteOffset + data.startIndex)
        let range = start..<(start + byteCount)
        
        data.copyBytes(to: buffer, from: range)
        
        if bigEndian {
            buffer.swapAt(0, 3)
            buffer.swapAt(1, 2)
        }
        
        byteOffset += byteCount
    }
}
