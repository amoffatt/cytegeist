//
//  TreeNode.swift
//  filereader
//
//  Created by Adam Treister on 7/24/24.
//

import Foundation


//public typealias AttributeStore = [String:String]


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

public class TreeNode
{
    public var value = ""
    public var attrib = AttributeStore()
    public var children = [TreeNode]()
    public var text = ""
    
    public init(_  t: String )          {    value = t    }
    public func add(child: TreeNode)    {    children.append(child)    }
    public var deepCount: Int           {    1 + children.reduce(0) { $0 + $1.deepCount }    }
    
    public func findChild(value: String) -> TreeNode?
    {
        children.first(where: {   node  in node.value == value        })
    }
    
    public func findChildren(value: String) -> [TreeNode]    {
        return children.filter( {    $0.value == value    } )
    }
}
