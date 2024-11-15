//
//  CGTableModel.swift
//  CytegeistApp
//
//  Created by Adam Treister on 9/2/24.
//

import Foundation
import CytegeistCore
import CytegeistLibrary
import SwiftUI



public struct TableBuilder : View
{
    @Environment(Experiment.self) var experiment
    @State var selectedTable:CGTable? = nil
    @State private var selectedPop: String = ""
    @State private var selectedParm: String = ""
    @State private var selectedKeyword: String = ""
    @State private var selectedColumnA: String = ""
    @State private var selectedColumnB: String = ""

    var TableTools : some View {
        
        TabView {
            VStack {
                HStack {
                    
                    Text("Populations: ").font(.title2)
                    Picker("", selection: $selectedPop,  content: {
                        ForEach(experiment.populationNames()) {  Text($0)  }
                    }).frame(maxWidth: 350)
                    Spacer()
                    Text("Parameters: ").font(.title2)
                    Picker("", selection: $selectedParm,  content: {
                        ForEach(experiment.parameterNames()) {  Text($0)  }
                    }).frame(maxWidth: 350)
                    
                }
                
                HStack {
                    Button("Frequency", action: {  selectedTable?.addStat(selectedPop, "freq", "", experiment: experiment)}).buttonBorderShape(.capsule)
                    Button("... of Parent", action: {  selectedTable?.addStat(selectedPop, "freqOf", "", experiment: experiment)}).buttonBorderShape(.capsule)
                    Spacer()
                    Button("Median", action: {  selectedTable?.addStat(selectedPop, "median", selectedParm, experiment: experiment)}).buttonBorderShape(.capsule)
                    Button("CV",    action: {   selectedTable?.addStat(selectedPop, "cv",  selectedParm, experiment: experiment)}).buttonBorderShape(.capsule)
                        //                Button("Mean", action: {    selectedTable?.addStat(selectedPop, "mean", selectedParm)}).buttonBorderShape(.capsule)
                        //                Button("StDev", action: {   selectedTable?.addStat(selectedPop, "stdev", selectedParm)}).buttonBorderShape(.capsule)
                        //                Button("5%, 95%", action: {   selectedTable?.addStat("percentile595")}).buttonBorderShape(.capsule)
                        //                Button("...",    action: {  }).buttonBorderShape(.capsule)
                    
                }
            }.tabItem( { Text("Statistics") } )         //--------------------------------------
            
             HStack {
                VStack {
                    HStack {
                        
                        Text("Keywords: ").font(.title2)
                        Picker("", selection: $selectedKeyword,  content: {
                            ForEach(experiment.keywordNames()) {  Text($0)  }
                        })
                        Button("Add", systemImage: "plus", action: {  selectedTable?.addKeyword(selectedKeyword)}).buttonBorderShape(.capsule)
                        Spacer()
                        
                    }
                        //                    Text("-- or --")
                }.frame(maxWidth: 350)
                Spacer()
            }.tabItem( { Text("Keywords") } )        //--------------------------------------


            VStack {
                 HStack {
                    
                    Text("Column A: ").font(.title2)
                    Picker("", selection: $selectedColumnA,  content: {
                        ForEach(colNames()) {  Text($0)  }
                    }).frame(maxWidth: 350)
                }
                HStack {
                    Text("Column B: ").font(.title2)
                    Picker("", selection: $selectedColumnB,  content: {
                        ForEach(colNames()) {  Text($0)  }
                    }).frame(maxWidth: 350)
                }
                                
                HStack {
                    Button("1 / A", action: {  addStat("reciprocal")}).buttonBorderShape(.capsule)
                    Button("A + B", action: {  addStat("sum")}).buttonBorderShape(.capsule)
                    Button("A - B", action: {  addStat("difference")}).buttonBorderShape(.capsule)
                    Button("A * B", action: {  addStat("product")}).buttonBorderShape(.capsule)
                    Button("A / B", action: {  addStat("ratio")}).buttonBorderShape(.capsule)
                    Spacer()
                }
            }.tabItem( { Text("Calculated Columns") } )        //--------------------------------------
            
        }.padding(8)
        .frame(maxHeight: 120)
    }
    //--------------------------------------
     func addStat(_ action: String)
    {
        if let selectedTable {
            selectedTable.addStat(action, colA: selectedColumnA, colB: selectedColumnB)
        }
    }
    
    func colNames() -> [String]
    {
        if let selectedTable {
            return selectedTable.items.compactMap( { $0.colname() } )
        }
        return ["age", "height", "weight"]          //TODO
    }
    //--------------------------------------

    
    public var body: some View {
        return VStack {
            TabBar(experiment.tables, selection:$selectedTable) { table in
                Text(table.name)
            } 
            add:    {  addTable()   }
            remove: {  table in experiment.tables.removeAll { $0 == table } }
            
            VStack {
                if let selectedTable {
                    if selectedTable.isTemplate 
                    {
                        TableTools
                        CGTableTemplateView(table:selectedTable)
                    }
                    else
                    {
                        CGTableResultView(table:selectedTable)
                    }
                } else {  Text("Select a Table") }
            }
            .fillAvailableSpace()
        }
        .onAppear {
            if experiment.tables.isEmpty {
                selectedTable = experiment.addTable()
            }
        } .toolbar {  ToolbarItem(placement: .primaryAction) {
            HStack {
                Spacer(minLength: 200 )
                Button("Batch", action: {   doBatch()   }).buttonBorderShape(.capsule)
            }
        }
        }
    }
    
//---------------------------------------------------------------------------

    func addTable()
    {
        let table = CGTable(isTemplate: true)
        table.name = table.name.generateUnique(existing: experiment.tables.map { $0.name })
        experiment.tables.append(table)
        selectedTable = table

    }
    // called by doBatch, isTemplate: false
    func addTable(cols: [TColumn], rows: [Row])
    {
        print ("called by doBatch")
        var namedCols = cols
        namedCols.insert(TColumn("Sample", stat: "Name"), at: 0)
        let table = CGTable(cols: namedCols, rows: rows)
        table.name = table.name.generateUnique(existing: experiment.tables.map { $0.name })
        experiment.tables.append(table)
        selectedTable = table
    }

//---------------------------------------------------------------------------
    func stat(_  sample: Sample, _  col: TColumn) -> String
    {
        return ("(\(col.parm), \(col.pop), \(col.stat))")
    }
    
    func doBatch()
    {
        if let selectedTable {
            var cells = [Row]()
//            let cols = selectedTable.items.map( { $0.toString() })
            let activeSamples = experiment.getSamplesInCurrentGroup()
            if !activeSamples.isEmpty {
                
                for sample in activeSamples {
                    var row = Row()
                    row.cells.append(sample.tubeName)
                    for col in selectedTable.items {
                        row.cells.append(stat(sample, col))
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

let FormatTypes = ["None", "HeatMap", "StdDevs", "Range"]

public struct CGTableTemplateView : View {
    @State var selection = Set<TColumn.ID>()
    @State var sortOrder = [KeyPathComparator(\TColumn.pop, order: .forward), KeyPathComparator(\TColumn.parm, order: .forward)]
    @State var columnCustomization = TableColumnCustomization<TColumn>()
    @State var selectedFormat = "None"

    let table: CGTable
    
    public var body: some View {
            //            Table (of: TColumn.Type, selection: $selectedColumns)
        Table (selection: $selection, sortOrder: $sortOrder, columnCustomization: $columnCustomization)
        {
            TableColumn("Population", value: \.pop){ col in Text(col.pop)}
                .width(min: 100, ideal: 180)
                .customizationID("name")
             TableColumn("Statistic", value: \.stat){ col in Text(col.stat)}
                .width(min: 30, ideal: 80, max: 120)
                .customizationID("stat")
            TableColumn("Parameter", value: \.parm){ col in Text(col.parm)}
                .width(min: 100, ideal: 180)
                .customizationID("parm")
            TableColumn("Arg", value: \.arg){ col in Text(col.arg)}
                .width(min: 30, ideal: 50, max: 460)
                .customizationID("arg")
            TableColumn("Label", value: \.label){ col in TextField(col.label, text: $selectedFormat)}           // TODO  Binding to col.label
                .width(min: 30, ideal: 150, max: 460)
                .customizationID("label")
            TableColumn("Format", value: \.format) { col in
                    Picker("", selection: $selectedFormat, content: { ForEach(FormatTypes) {  Text($0)  } })   // TODO  Binding to col.format
                }
                .width(min: 80, ideal: 100, max: 140)
                .customizationID("format")
        }
        
    rows: {
        ForEach(table.items)  { col in TableRow(col) }
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
//-------------------------------------------------------------------------
public struct CGTableResultView : View {
    @State var selection = Set<TColumn.ID>()
    @State var sortOrder = [KeyPathComparator(\TColumn.pop, order: .forward), KeyPathComparator(\TColumn.parm, order: .forward)]
    @State var columnCustomization = TableColumnCustomization<TColumn>()
    
    let table: CGTable
    
    
    
    public var body: some View {
            //            Table (of: TColumn.Type, selection: $selectedColumns)
        
        if let t = table.cells {
            Table (t)
            {
                let colnames = table.items.map( { $0.colname() })
                TableColumnForEach(0..<colnames.count, id: \.self) { i in
                    TableColumn("\(colnames[i])") { _ in  Text(colnames[i])  }
                }
            }
        }
    }
}
