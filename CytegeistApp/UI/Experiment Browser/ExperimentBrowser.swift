//
//  ExperimentBrowser.swift
//  CytegeistApp
//
//  Created by Adam Treister on 9/17/24.
//

import Foundation
import SwiftUI
import CytegeistLibrary
import CytegeistCore

import UniformTypeIdentifiers


struct ExperimentBrowser : View {
    
    @Environment(App.self) var app: App
    
    
    var body: some View {
//        @Bindable var app = app
        
        NavigationSplitView {
            BrowserSidebar()
        }
    content:
        {
            PanelA()
//            TableBuilder()
                .navigationSplitViewColumnWidth(min: 200, ideal: 700, max: .infinity)
        }
    detail: {
        VStack {
            PanelB()
         }
        .navigationSplitViewColumnWidth(min: 300, ideal: 600, max: .infinity)
        
        }
    }
    
        //
    struct BrowserSidebar :  View {
        
        var body : some View   {
            Text("Servers").font(.title2)
            Text("Local").font(.title3)
            Text("OMIPS").font(.title3)
            Text("FlowRepository").font(.title3)
        }
        
    }
    
    struct PanelA :  View {
        
        var body : some View
        {
            XTableView()
        }
        
    }
    struct PanelB :  View {
        
        var body : some View
        {
            MIFlowCytView().offset(x: 36, y: 36)
        }
        
    }
    
        //---------------------------------------------------------------------------
        // Model
    
    @Observable
    public class XTable : Usable  //, Hashable
    {
        public static func == (lhs: XTable, rhs: XTable) -> Bool {
            lhs.id == rhs.id
        }
        
//        public func hash(into hasher: inout Hasher) {
//            hasher.combineMany(id, primary,keywords, experiement, species, date )
//        }
        
        public var id = UUID()
        public  var name = "Untitled Table"
        public var items = [XColumn]()
            //    var info = BatchInfo()
        
        init() {    }
    }


    public struct XColumn : Identifiable, Hashable, Codable
    {
        public var id = UUID()
        var primary: String = " "
        var keywords: String = " "
        var experiement: String = " "
        var species: String = " "
        var date: String = " "

        init(_ name: String, parm: String, stat: String, arg: String = " ")
        {
            self.date = name
            self.primary = parm
            self.keywords = stat
            self.experiement = arg
            self.species = arg
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combineMany(date, primary, keywords, experiement, species)
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
    }

    
    public struct XTableView : View {
  
        @State var selection = Set<XColumn.ID>()
        @State var sortOrder = [KeyPathComparator(\XColumn.primary, order: .forward),
                                KeyPathComparator(\XColumn.experiement, order: .forward),
                                KeyPathComparator(\XColumn.keywords, order: .forward),
                                KeyPathComparator(\XColumn.species, order: .forward),
                                KeyPathComparator(\XColumn.date, order: .forward)   ]
        @State var columnCustomization = TableColumnCustomization<XColumn>()
        
        let table =  XTable()
        
        public var body: some View {
                //            Table (of: TColumn.Type, selection: $selectedColumns)
            Table (selection: $selection, sortOrder: $sortOrder, columnCustomization: $columnCustomization)
            {
                TableColumn("Date", value: \.date){ col in Text(col.date)}
                    .width(min: 130, ideal: 180)
                    .customizationID("date")
                TableColumn("Primary", value: \.date){ col in Text(col.primary)}
                    .width(min: 130, ideal: 180)
                    .customizationID("primary")
                TableColumn("Experiment", value: \.experiement){ col in Text(col.experiement)}
                    .width(min: 30, ideal: 80, max: 160)
                    .customizationID("experiment")
                TableColumn("Keywords", value: \.keywords){ col in Text(col.keywords)}
                    .width(min: 30, ideal: 50, max: 60)
                    .customizationID("keywords")
                TableColumn("Species", value: \.species){ col in Text(col.species)}
                    .width(min: 30, ideal: 50, max: 60)
                    .customizationID("species")
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
//                .dropDestination(for: AnalysisNode.self) { (items, position) in
//                    for item in items {print(item.name)  }
//                    
//                    for item in items { newTableItem(node: item, position:position)  }
//                    return true
//                }
                //            .opacity(mode == .table ? 1.0 : 0.3)
        }
//        
//        func newTableItem(node:AnalysisNode, position:CGPoint)
//        {
//            table.items.append(TColumn("", parm: "Keyword", stat: "Date"))
//            table.items.append(TColumn(node.name, parm: "CD3", stat: "Median"))
//            table.items.append(TColumn(node.name, parm: "CD3", stat: "CV"))
//            print("new table item: ", node.name)
//        }
//        
        
    }
}
