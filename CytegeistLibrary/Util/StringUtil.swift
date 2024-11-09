//
//  StringUtil.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/14/24.
//

import Foundation
import CryptoKit
import SwiftUI


let DEBUG = true
public func debug(_ s: String)
{
if (DEBUG)  {
    print (s)
}
}
public func debug(_ s: String, t: String)
{
if (DEBUG)  {
    print (s, t)
}
}


public func dateStr(_ date: Date) -> String
{
    let myDateFormatter = DateFormatter()
    myDateFormatter.dateFormat = "YYMMDD"
    return myDateFormatter.string(from: date)
}

private let newline = "\n".data(using: .utf8)!
private let comma = ",".data(using: .utf8)!

public func isEmpty(_ value:String?) -> Bool {
    value?.isEmpty ?? true
}

public func nonNil(_ value:String?) -> String {
    value ?? ""
}
public extension Bool {
     func xml() -> String {     return self ? "true" : "false"   }
}

public extension CGPoint {
    func xml() -> String {     return "<Point x=\(self.x) y=\(self.y) /> \n"   }
}

public extension CGSize {
    func xml() -> String {     return "<Size width=\(self.width) y=\(self.height) /> \n"   }
}

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
    
    ///  UTF8 encoded data of this string
    var utf8Data:Data? { self.data(using: .utf8) }
    
    subscript(_ index: Int) -> Character? {
        guard index >= 0, index < self.count else {
            return nil
        }
        
        return self[self.index(self.startIndex, offsetBy: index)]
    }
    
    subscript(_ range: Range<Int>) -> String {
        guard let start = self.index(self.startIndex, offsetBy: range.lowerBound, limitedBy: self.endIndex),
              let end = self.index(self.startIndex, offsetBy: range.upperBound, limitedBy: self.endIndex),
              start <= end else {
            return ""
        }
        return String(self[start..<end])
    }

    func substring(offset: Int, length: Int) -> String {
        let end = offset + length
        return self[offset..<end]
    }

    func toColor( ) -> Color {
        return Color.blue
    }
    
    func stripHead() -> String {
        
        if let a = self.range(of:"<head>") {
            if let z = self.range(of: "</head>") {
                let tail = self[z.upperBound...]
                return String(tail)
            }
        } 
        return self.replacingOccurrences(of: "<head>[^>]+</head>", with: "", options: .regularExpression, range: nil)
    }
    func withoutHtmlTags() -> String {
        
        let s = stripHead()
        let str = s.replacingOccurrences(of: "<style>[^>]+</style>", with: "", options: .regularExpression, range: nil)
        return str.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
    
    func splitWithDoubleEscaping(separator:String) -> [String] {
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
    
    func trim(_ characters:CharacterSet = .whitespacesAndNewlines) -> String {
        self.trimmingCharacters(in: characters)
    }
    
    func generateUnique(existing: any Collection<String>) -> String {
        var uniqueName = self
        var counter = 1
        
        while existing.contains(uniqueName) {
            uniqueName = "\(self) - \(counter)"
            counter += 1
        }
        
        return uniqueName
    }
    
    func nonEmpty(_ defaultValue:String) -> String {
        self.isEmpty ? defaultValue : self
    }
    
    
    func contains(_ find: String) -> Bool{
        return self.range(of: find) != nil
    }
    
    func containsIgnoringCase(_ find: String) -> Bool{
        return self.range(of: find, options: .caseInsensitive) != nil
    }
    func preprocessK() -> String{
        if let idx = firstIndex(of: ".")
        {
            let str = prefix(upTo: idx)
            if str.count > 4 {
                return str.prefix(str.count-3)  + "M"
            }
            return str + "K"
        }
        return self
    }
    
    func preprocessM() -> String{
        if let idx = firstIndex(of: ".")
        {
            let str = prefix(upTo: idx)
            if str.count > 4 {
                return str.prefix(str.count-3)  + "G"
            }
            return str + "M"
        }
        return self
    }

}

public extension Double {
    // func asPercentage(decimals: Int = 1) -> String {
    //     let formatter = NumberFormatter()
    //     formatter.numberStyle = .percent
    //     formatter.minimumFractionDigits = decimals
    //     formatter.maximumFractionDigits = decimals
    //     return formatter.string(from: self as! NSNumber) ?? ""
    // }

    func asPercentage() -> String {
        let multiplied = self * 100
        return String(format: "%.1f%%", multiplied)
    }
}


public extension Optional where Wrapped == String {
    var nonNil:String { self ?? "" }
    func nonEmpty(_ defaultValue:String) -> String {
        self.nonNil.isEmpty ? defaultValue : self!
    }
}

public extension Data {
    func string(_ encoding:String.Encoding) -> String? {
        String(data:self, encoding:encoding)
    }
}


