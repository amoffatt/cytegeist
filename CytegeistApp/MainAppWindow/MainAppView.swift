//
//  NavView.swift
//  filereader
//
//  Created by Adam Treister on 7/28/24.
//

import SwiftUI

struct MainAppView : View {
   
    @Environment(App.self) var app: App

    @State  var mode =  ReportMode.layout
//    @State private var path = [Int]()
    @State private var  cols = [TColumn]()

    struct TColumn : Identifiable
    {
       var id = UUID()
        var name: String = ""
        var width: Int = 50
    }
    
    var tableBuilder : some View
    {
        VStack {
            Text("TableView")
            Table (cols)
            {
                TableColumn("Column Name"){ col in Text(String(col.name))}
                    .width(min: 130, ideal: 180)
                    .customizationID("name")
                TableColumn("Width"){ col in Text(String(col.width))}
                    .width(min: 30, ideal: 50, max: 60)
                    .customizationID("width")
            } .frame(minWidth: 300, idealWidth: 600)
        }
        .opacity(mode == .table ? 1.0 : 0.3)
    }
    

    var body: some View {
        
        // AM Note: If we need to support Pre-macOS13, see https://developer.apple.com/documentation/swiftui/migrating-to-new-navigation-types
        NavigationSplitView {
            MainAppSidebar()
        }
        content:
        {
            HSplitView {
                Group {
                    if let selected = app.getSelectedExperiment() {
                        SampleList(experiment: selected)
                            .frame(minWidth: 100, idealWidth: 600)
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
                
                AnalysisList()                  // sidebar
                    .frame(minWidth: 250, idealWidth: 600, maxWidth: .infinity)
            }
            .navigationSplitViewColumnWidth(min: 600, ideal: 1600, max: .infinity)
        }
        detail: {
//            NavigationSplitView {           //Nested split view
//                }
//            detail: {
            Group {
                if mode == .table        {   tableBuilder     }
                else if mode == .gating  {   GatingView()     }
                else                     {   LayoutPasteboard(mode: mode)   }
                //            }
            }
            .navigationSplitViewColumnWidth(min: 300, ideal: 1200, max: .infinity)
            .toolbar {
                ReportModePicker(mode: $mode)
            }
            
         }
        .onAppear {
            app.getSelectedExperiment(autoselect: true, createIfNil: true)
        }
    }
}
