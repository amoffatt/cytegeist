//
//  TreeNode.swift
//  filereader
//
//  Created by Adam Treister on 7/24/24.
//

import Foundation

class TreeNode
{
    public var value = ""
    public var attrib = [String: String]()
    public var children = [TreeNode]()
    public var text = ""
    
    init(_   t: String )    {
        value = t
    }
    func add(child: TreeNode) {
        children.append(child)
    }
    var deepCount: Int {
        1 + children.reduce(0) { $0 + $1.deepCount }
    }
    
    public func findChild(value: String) -> TreeNode?
    {
        children.first(where: {
            node  in node.value == value
        })
    }
    
    public func findChildren(value: String) -> [TreeNode]?    {
        return children.filter( {    $0.value == value    } )
    }
}
