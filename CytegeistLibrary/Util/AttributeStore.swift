//
//  AttributeStore.swift
//  CytegeistLibrary
//
//  Created by Adam Treister on 11/8/24.
//

import Foundation

public class AttributeStore: Codable, Hashable
{
    public init () {
        dictionary = [String:String]()
    }
    
    public static func == (lhs: AttributeStore, rhs: AttributeStore) -> Bool {
        if lhs.dictionary.count != rhs.dictionary.count { return false}
        
        for pair in lhs.dictionary {
            if rhs.dictionary[pair.key] != pair.value {return false}
        }
        return true
    }
    public func hash(into hasher: inout Hasher)
    {
        
    }
    public var dictionary: [String:String]
    
    
    public func xml() -> String {
        
        var str = "<Keywords>\n"
        for pair in dictionary {
            str.append("<Keyword name=\(pair.key) value=\(pair.value)\n")
        }
        return str + "</Keywords>\n"
    }
    
}
