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
        //        @State var selectedColumns = Set<TColumn.ID>()
    @State var selectedTable:CGTable? = nil
    
    public var body: some View {
        return VStack {
            TabBar(experiment.tables, selection:$selectedTable) { table in
                Text(table.name)
            } add: {
                let table = CGTable()
                table.name = table.name.generateUnique(existing: experiment.tables.map { $0.name })
                experiment.tables.append(table)
                selectedTable = table
            } remove: { table in
                experiment.tables.removeAll { $0 == table }
            }
            VStack {
                    //            .opacity(1.0)
                if let selectedTable {
                    CGTableView(table:selectedTable)
                } else {
                    Text("Select a Table")
                }
            }
            .fillAvailableSpace()
        }
        .onAppear {
            if experiment.tables.isEmpty {
                selectedTable = experiment.addTable()
            }
        }
    }
}
//------------------------------------------------------------------------------------


public struct CGTableView : View {
    @State var selection = Set<TColumn.ID>()
    @State var sortOrder = [KeyPathComparator(\TColumn.pop, order: .forward), KeyPathComparator(\TColumn.parm, order: .forward)]
    @State var columnCustomization = TableColumnCustomization<TColumn>()
    
    let table:CGTable
    
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
        table.items.append(TColumn("", parm: "Keyword", stat: "Date"))
        table.items.append(TColumn(node.name, parm: "CD3", stat: "Median"))
        table.items.append(TColumn(node.name, parm: "CD3", stat: "CV"))
        print("new table item: ", node.name)
    }
    
    
}
//---------------------------------------------------------------------------
// Model

@Observable
public class CGTableModel : Usable, Hashable
{
    public static func == (lhs: CGTableModel, rhs: CGTableModel) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combineMany(id, name)
    }
    
    public var id = UUID()
    public  var name = "Untitled Table"
    public var items = [TColumn]()
        //    var info = BatchInfo()
    
    init() {    }
}

// model for an individual column, which is actually a row in the table editor
public struct TColumn : Identifiable, Hashable, Codable
{
    public var id = UUID()
    public var pop: String = " "
    var parm: String = " "
    var stat: String = " "
    var arg: String = " "
    
    public func hash(into hasher: inout Hasher) {
        hasher.combineMany(id, pop, parm, stat, arg)
    }
    
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
    init(_ name: String, parm: String, stat: String, arg: String = " ")
    {
        self.pop = name
        self.parm = parm
        self.stat = stat
        self.arg = arg
    }
}


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
//    var info = BatchInfo()
    
    init() {    }
}
 
