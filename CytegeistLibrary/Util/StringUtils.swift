//
//  StringUtil.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/14/24.
//

import Foundation


public extension String {
    //    func substring(offset: Int, length: Int) -> String {
    //        guard offset >= 0, length > 0, offset < self.count else {
    //            return ""
    //        }
    //        let start = self.index(self.startIndex, offsetBy: offset)
    //        let endOffset = min(offset + length, self.count)
    //        let end = self.index(self.startIndex, offsetBy: endOffset)
    //        return String(self[start..<end])
    //    }
    
    public func substring(_ range: Range<Int>) -> String {
        guard let start = self.index(self.startIndex, offsetBy: range.lowerBound, limitedBy: self.endIndex),
              let end = self.index(self.startIndex, offsetBy: range.upperBound, limitedBy: self.endIndex),
              start <= end else {
            return ""
        }
        return String(self[start..<end])
    }

    public func substring(offset: Int, length: Int) -> String {
        let end = offset + length
        return self.substring(offset..<end)
    }
    
    public func splitWithDoubleEscaping(separator:String) -> [String] {
        let escape = separator + separator
        
        let nested_split = self.split(separator:escape).map { x in
            x.split(separator: separator)
        }
        
        var result:[String] = .init()
        
        for subsequence in nested_split {
            var strings = subsequence.map { String($0) }
            
            if !result.isEmpty {
                result[result.endIndex - 1] += separator + strings.removeFirst()
            }
            
            result.append(contentsOf: strings)
        }
        
        return result
    }
    
    public func trim(_ characters:CharacterSet = .whitespacesAndNewlines) -> String {
        self.trimmingCharacters(in: characters)
    }
    
}

public extension Optional where Wrapped == String {
    public var nonNil:String { self ?? "" }
}

public extension Data {
    public func string(_ encoding:String.Encoding) -> String? {
        String(data:self, encoding:encoding)
    }
}
