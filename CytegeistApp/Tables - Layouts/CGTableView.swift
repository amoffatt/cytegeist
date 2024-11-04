//
//  CGTableModel.swift
//  CytegeistApp
//
//  Created by Adam Treister on 9/2/24.
//

import Foundation
import UniformTypeIdentifiers
import CytegeistCore
import CytegeistLibrary
import SwiftUI



public struct TableBuilder : View
{
    @Environment(Experiment.self) var experiment
    @State var selectedTable:CGTable? = nil
    
    var TableTools : some View {
        
        HStack {
            Spacer()
            Text("        ")
            Menu("Populations"){
                Button("All Cells", action: {})
                Button("Lymphocytes", action: {})
                Button("TCells", action: {})
            }
            Menu("Parameters"){
                Button("FSC", action: {})
                Button("SSC", action: {})
                Button("PE", action: {})
                Button("FITC", action: {})
                Button("Cy7-PE", action: {})
            }
            Button("Median", action: {  addStat(stat: "median")}).buttonBorderShape(.capsule)
            Button("CV",    action: {   addStat(stat: "cv")}).buttonBorderShape(.capsule)
            Button("...",    action: {  }).buttonBorderShape(.capsule)
//            Button("Mean", action: {    addStat(name: "mean")}).buttonBorderShape(.capsule)
//            Button("StDev", action: {   addStat(name: "stdev")}).buttonBorderShape(.capsule)
//            Button("5%, 95%", action: {   addStat(name: "percentile595")}).buttonBorderShape(.capsule)
            Spacer()
           Button("Batch", action: {   doBatch()   }).buttonBorderShape(.capsule)
        }
    }
        public var body: some View {
        return VStack {
            TabBar(experiment.tables, selection:$selectedTable) { table in
                Text(table.name)
            } 
            add:    {  addTable()   }
            remove: {  table in experiment.tables.removeAll { $0 == table } }
            
            VStack {
                if let selectedTable {
                    CGTableView(table:selectedTable)
                } else {  Text("Select a Table") }
            }
            .fillAvailableSpace()
        }
        .onAppear {
            if experiment.tables.isEmpty {
                selectedTable = experiment.addTable()
            }
        }.toolbar { TableTools }
    }
    
        //---------------------------------------------------------------------------
    func addStat(stat: String)
    {
            //        table.addNode(node)
    }
    func addTable()
    {
        let table = CGTable()
        table.name = table.name.generateUnique(existing: experiment.tables.map { $0.name })
        experiment.tables.append(table)
        selectedTable = table

    }
    
    func addTable(cols: [TColumn], rows: [[String]])
    {
        let table = CGTable(cols: cols, rows: rows)
        table.name = table.name.generateUnique(existing: experiment.tables.map { $0.name })
        experiment.tables.append(table)
        selectedTable = table
    }

    //---------------------------------------------------------------------------
    func stat(_  sample: Sample, _  col: TColumn) -> String
    {
        return ("stat (\(col.parm), \(col.pop), \(col.stat))")
    }
    
    func doBatch()
    {
        if let selectedTable {
            var cells = [[String]]()
//            let cols = selectedTable.items.map( { $0.toString() })
           let activeSamples = experiment.getSamplesInCurrentGroup()
            if !activeSamples.isEmpty {
                
                for sample in activeSamples {
                    var row = [String]()
                    row.append(sample.tubeName)
                    for col in selectedTable.items {
                        row.append(stat(sample, col))
                    }
                    cells.append(row)
                }
                addTable(cols: selectedTable.items, rows: cells)
                for row in cells { print( row)    }
                
            } else { print("no samples in current group")   }
            
        } else { print("doBatch with no selected table")   }
    }
}
//------------------------------------------------------------------------------------


public struct CGTableView : View {
    @State var selection = Set<TColumn.ID>()
    @State var sortOrder = [KeyPathComparator(\TColumn.pop, order: .forward), KeyPathComparator(\TColumn.parm, order: .forward)]
    @State var columnCustomization = TableColumnCustomization<TColumn>()
    
    let table: CGTable
    
    public var body: some View {
            //            Table (of: TColumn.Type, selection: $selectedColumns)
        Table (selection: $selection, sortOrder: $sortOrder, columnCustomization: $columnCustomization)
        {
            TableColumn("Population", value: \.pop){ col in Text(col.pop)}
                .width(min: 130, ideal: 180)
                .customizationID("name")
            TableColumn("Parameter", value: \.parm){ col in Text(col.parm)}
                .width(min: 130, ideal: 180)
                .customizationID("parm")
            TableColumn("Statistic", value: \.stat){ col in Text(col.stat)}
                .width(min: 30, ideal: 80, max: 160)
                .customizationID("stat")
            TableColumn("Arg", value: \.arg){ col in Text(col.arg)}
                .width(min: 30, ideal: 50, max: 60)
                .customizationID("arg")
        }
    rows: {
        ForEach(table.items)  { col in TableRow(col) }
            //                ForEach(cols) { col in TableRow(TColumn).itemProvider { TColumn.itemProvider }  }
            //                    .onInsert(of: [TColumn.draggableType]) { index, providers in
            //                        TColumn.fromItemProviders(providers) { cols in
            ////                            let experiment = store.getSelectedExperiment()
            ////                            experiment.samples.insert(contentsOf: samples, at: index)
            //                        }
            //                    }
        
    }.frame(minWidth: 300, idealWidth: 600)
        .dropDestination(for: AnalysisNode.self) { (items, position) in
            for item in items {print(item.name)  }

            for item in items { newTableItem(node: item, position:position)  }
            return true
        }
        //            .opacity(mode == .table ? 1.0 : 0.3)
    }
    
    func newTableItem(node:AnalysisNode, position:CGPoint)
    {
        table.addNode(node)
    }
    
 

}
//---------------------------------------------------------------------------
// Model

@Observable
public class CGTable : Usable, Hashable
{
    public static func == (lhs: CGTable, rhs: CGTable) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combineMany(id, name)
    }
    
    public var id = UUID()
    public  var name = "Untitled Table"
    public var items = [TColumn]()
    public var rows: [[String]]?
    public var isTemplate = true
        //    var info = BatchInfo()
    
    init() {    }
    init(cols: [TColumn], rows: [[String]]? )
    {
        self.items = cols
        self.rows = rows
    }
    
    public func addNode(_ node: AnalysisNode)
    {
        items.append(TColumn(node.name, stat: "Freq"))
    }
    
    public func xml() -> String {
        return "<Table " + attributes() + " >\n\t<Columns>" +
        items.compactMap { $0.xml() }.joined(separator: "\n\t") +   "</Columns>\n" +
        "</Table>\n"
        
    }
    
    public func attributes() -> String {
        
            return "name=" + name
    }
 
}

//---------------------------------------------------------------------------
// model for an individual column, which is a row in the table editor
// and a column in the result of a batch

public struct TColumn : Identifiable, Hashable, Codable
{
    public var id = UUID()
    public var pop: String = " "
    var stat: String = " "
    var parm: String = " "
    var arg: String = " "
 
    init(_ name: String, stat: String, parm: String = "", arg: String = "")
    {
        self.pop = name
        self.stat = stat
        self.parm = parm
        self.arg = arg
    }

    public func toString() -> String {   "\(pop)\n \(stat) \(parm) \(arg)"   }
    public func hash(into hasher: inout Hasher) {
        hasher.combineMany(id, pop, parm, stat, arg)
    }
 
    public func xml() -> String {   "<Column \(pop)\n \(stat) \(parm) \(arg) >\n"   }

    
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

