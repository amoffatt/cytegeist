import Foundation
import CytegeistLibrary
import CytegeistCore


//---------------------------------------------------------
//https://blog.logrocket.com/xml-parsing-swift/
class WorkspaceReader {
    func readWorkspaceFile(at url: URL) async throws -> TreeNode {
        
        let data = try Data(contentsOf: url)
        
        // Read header
        let header = String(data: data.prefix(50), encoding: .ascii)!
        guard header.hasPrefix("<?xml version=") else {
            throw NSError(domain: "WorkspaceReaderError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid Workspace file format"])
            
        }
        let parserDelegate = WSParserDelegate()
        let parser =  XMLParser(contentsOf: url)
        parser?.delegate = parserDelegate
        parser?.parse()
        return parserDelegate.parentStack.last!
    }
    
    
    class WSParserDelegate : NSObject, XMLParserDelegate {
        
        public var parentStack = [TreeNode]()
        
        override init ()
        {
            parentStack.append(TreeNode("root"))
        }
        
        //START ELEMENT
        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
            
            let node = TreeNode(elementName)
            for entry in attributeDict {
                node.attrib.dictionary[entry.key] = entry.value
            }
            //            print ("Pushing ", elementName, parentStack.count)
            parentStack[parentStack.endIndex-1].add(child: node)        //add the new node to parent's children
            parentStack.append(node)             // PUSH OUR NODE onto the parentStack
        }
        //END OF ELEMENT TAG
        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
        {
            parentStack.removeLast() // POP
            //            print("Parsed  \(elementName) \(parentStack.count) ")
        }
        
        //CDATA PROCESSING  -- only affects us in Table/Layout Headers and Footers
        func parser( foundCharacters string: String) {
            let s = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !s.isEmpty {
                print ("CDATA " + s)
                parentStack[parentStack.endIndex-1].attrib.dictionary["CDATA"] = s
            }
        }
    }
}


//
//struct Criterion : Codable
//{
//    var attributes = [String : String]()
//    init(fjxml: TreeNode)
//    {
//    }
//}

//extension Statistic {
//    init(fjxml: TreeNode)
//    {
//        extraAttributes.merge(fjxml.attrib, uniquingKeysWith: +)
//   }
//}
