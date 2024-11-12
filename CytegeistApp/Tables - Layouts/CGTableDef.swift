//
//  CGTable.swift
//  CytegeistApp
//
//  Created by Adam Treister on 11/9/24.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import CytegeistCore
import CytegeistLibrary

    //---------------------------------------------------------------------------
    // Model
@Observable
public class CGTable : Usable, Hashable  {
    public static func == (lhs: CGTable, rhs: CGTable) -> Bool {
        lhs.id == rhs.id
    }
    public var id: UUID = UUID()
    public var name: String = "Table"
//    public func xml() -> String { "" }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combineMany(id, name)
    }
    public var isTemplate = false
    
    public var items = [TColumn]()
    public var cells: [Row]?         // nil except when its the result of a batch
    
    public init(isTemplate: Bool ) {
        self.isTemplate = isTemplate
    }

    init(cols: [TColumn], rows: [Row])
    {
        self.items = cols
        self.cells = rows
        self.isTemplate = false
    }
    
    public init(_ node: TreeNode ) {
    }
    
    required public init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
//------------------------------------------------------
    public func addNode(_ node: AnalysisNode)
    {
        items.append(TColumn(node.name, stat: "Freq"))
    }
    
    public func addStat(_ name: String, _ stat: String, _ parm: String, experiment: Experiment)
    {
        if parm == "<All>"  {
            for param in experiment.parameterNames() {
                if param != "<All>" {
                    items.append(TColumn(name, stat: stat, parm: param))
                }
            }
        }
        else { items.append(TColumn(name, stat: stat, parm: parm)) }
    }
    
    public func addStat(_ stat: String, colA: String, colB: String)
    {
        items.append(TColumn("Computed", stat: stat, parm: colA, arg: colB))
    }
    
    public func addStat(_ str: String)
    {
        items.append(TColumn("current", stat: str))
    }
    
    public func addKeyword(_ str: String)
    {
        items.append(TColumn("", stat: str, parm: "Keyword"))
    }
    
   //------------------------------------------------------
    public func xml() -> String {
        return "<Table " + attributes() + " >\n\t<Columns>" +
        items.compactMap { $0.xml() }.joined(separator: "\n\t") +   "</Columns>\n" +
        "</Table>\n"
    }
    
    public func attributes() -> String {   return "name=" + name   }
   
 
}

    //---------------------------------------------------------------------------
    // model for an individual column, which is a row in the table editor
    // and a column in the result of a batch

public struct TColumn : Identifiable, Hashable, Codable
{
    public var id = UUID()
    public var pop: String = ""
    var stat: String = ""
    var parm: String = ""
    var label: String = ""
    var arg: String = ""
    var format: String = ""

    init(_ name: String, stat: String, parm: String = "", label: String = "", arg: String = "", format: String = "")
    {
        self.pop = name
        self.stat = stat
        self.parm = parm
        self.label = label
        self.arg = arg
        self.format = format
    }
    
    public func toString() -> String {   "\(pop)\n \(stat) \(parm) \(arg) \(format)"   }
    public func hash(into hasher: inout Hasher) {
        hasher.combineMany(id, pop, parm, stat, arg, format)
    }
    
    public func colname() -> String
    {
//        if !self.label.isEmpty()     { return self.label   }
        return "\(pop)-\(stat)-\(parm)"
    }
   
    public func xml() -> String {   "<Column pop=\"\(pop)\" stat=\"\(stat)\" parm=\"\(parm)\" arg=\"\(arg)\" format=\"\(format)\" >\n"   }
    
    
    static var draggableType = UTType(exportedAs: "com.cytegeist.CyteGeistApp.tablecolumn")
    var itemProvider: NSItemProvider {
        let provider = NSItemProvider()
        provider.registerDataRepresentation(forTypeIdentifier: Self.draggableType.identifier, visibility: .all) {
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(self)
                $0(data, nil)
            } catch {
                $0(nil, error)
            }
            return nil
        }
        return provider
    }
}
    //---------------------------------------------------------------------------
// The arrary of strings output into a  CGTableResult
public struct Row: Usable {
    public var id = UUID()
    var cells: [String]
    
    public init ()    {
        self.cells = [String]()
    }
}

    //---------------------------------------------------------------------------
//
//@Observable
//public class CGTableResult : CGTable  ///Usable, Hashable  //, CGTable
//{
//    public static func == (lhs: CGTableResult, rhs: CGTableResult) -> Bool {
//        lhs.id == rhs.id
//    }
//    
//    public var cols: [TColumn]
//    public var rows: [Row]
//    
//
//    required init(from decoder: any Decoder) throws {
//        fatalError("init(from:) has not been implemented")
//    }
//    
//    func colNames() -> [String]    {
//        return cols.compactMap( { $0.colname() } )
//    }
//    
//    override public func xml() -> String   { return "<Table />" }  // TODO
//}
