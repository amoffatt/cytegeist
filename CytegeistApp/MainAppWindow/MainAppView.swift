//
//  NavView.swift
//  filereader
//
//  Created by Adam Treister on 7/28/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct MainAppView : View {
   
    @Environment(App.self) var app: App

    var mode:ReportMode { app.reportMode }
    
//    @State private var path = [Int]()
    @State private var  cols = [TColumn]()
        //----------------------------------------------------------------------------------
    
    struct TColumn : Identifiable, Codable
    {
        var id = UUID()
        var pop: String = " "
        var parm: String = " "
        var stat: String = " "
        var arg: String = " "
        
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
    
    var tableBuilder : some View
    {
            //        @State var selectedColumns = Set<TColumn.ID>()
        @State var selection = Set<TColumn.ID>()
        @State var sortOrder = [KeyPathComparator(\TColumn.pop, order: .forward), KeyPathComparator(\TColumn.parm, order: .forward)]
        @State var columnCustomization = TableColumnCustomization<TColumn>()
        
        return VStack {
            Text("TableView")
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
        rows: { ForEach(cols)  { col in TableRow(col) }
                //                ForEach(cols) { col in TableRow(TColumn).itemProvider { TColumn.itemProvider }  }
                //                    .onInsert(of: [TColumn.draggableType]) { index, providers in
                //                        TColumn.fromItemProviders(providers) { cols in
                ////                            let experiment = store.getSelectedExperiment()
                ////                            experiment.samples.insert(contentsOf: samples, at: index)
                //                        }
                //                    }
        }
            
        }.frame(minWidth: 300, idealWidth: 600)
            .dropDestination(for: AnalysisNode.self) { (items, position) in
                for item in items { newTableItem(node: item, position:position)  }
                return true
            }
            .opacity(mode == .table ? 1.0 : 0.3)
    }
    
    
    func newTableItem(node:AnalysisNode, position:CGPoint)
    {
        print("new table item: ", node.name)
        cols.append(TColumn(node.name, parm: " a", stat: "Freq. of Parent"))
        cols.append(TColumn(node.name, parm: "CD3", stat: "Median"))
        cols.append(TColumn(node.name, parm: "CD3", stat: "CV"))
            //        tableRows.addNode(node)
    }
    

    var body: some View {
        @Bindable var app = app
        
        // AM Note: If we need to support Pre-macOS13, see https://developer.apple.com/documentation/swiftui/migrating-to-new-navigation-types
        NavigationSplitView {
            MainAppSidebar()
        }
        content:
        {
                Group {
                    if let selected = app.getSelectedExperiment() {
                        HSplitView {
                            SampleList(experiment: selected)
                                .frame(minWidth: 100, idealWidth: 600)
                            
                            AnalysisList()
                                .frame(minWidth: 250, idealWidth: 600, maxWidth: .infinity, maxHeight: .infinity)
                                .fillAvailableSpace()
                        }
                        .environment(selected)
                        .onChange(of: selected.selectedSamples) {
                            selected.clearAnalysisNodeSelection()
                        }

                    } else {
                        ZStack {
                            VStack {
                                Text("No experiment selected...")
                                Button("Create New Experiment") {
                                    app.createNewExperiment()
                                }
                            }
                        }
                    }
                }
                .frame(minWidth: 250, idealWidth: 800, maxWidth: .infinity)
                .fillAvailableSpace()
                .navigationSplitViewColumnWidth(min: 600, ideal: 1600, max: .infinity)

        }
        detail: {
            if let experiment = app.getSelectedExperiment() {
                VStack {        // AM: VStack leads to better compile error messages than Group when the below code breaks (!?)
                    switch mode {
                    case .table: tableBuilder
                    case .gating: gatingBuilder(experiment)
                    case .layout: LayoutPasteboard(mode: mode)
                    }
                    
                }
                .environment(experiment)
                .environment(experiment.core)
                .navigationSplitViewColumnWidth(min: 300, ideal: 1200, max: .infinity)
                .toolbar {
                    ReportModePicker(mode: $app.reportMode)
                }
            }
            else {
                Text("Select an Experiment")
            }
            
         }
        .onAppear {
            app.getSelectedExperiment(autoselect: true, createIfNil: true)
        }
    }

//    func getFocusedPopulation() -> (Sample?, AnalysisNode?) {
//        
//    }
    
    func gatingBuilder(_ exp: Experiment) -> some View {
        VStack {
            if let node = exp.focusedAnalysisNode {
                GatingView(population:node)
            }
        }
    }
}
