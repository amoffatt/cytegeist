//
//  NavView.swift
//  filereader
//
//  Created by Adam Treister on 7/28/24.
//

import SwiftUI

struct   MainView : View {
   
    @EnvironmentObject var store: Store
    @Binding var selectedExperimentID: Experiment.ID?
    @State  var defaultExperimentID: Experiment.ID?

    private var selection: Binding<Experiment.ID?> {
        Binding(get: { selectedExperimentID ?? defaultExperimentID },
                set: { selectedExperimentID = $0 })
    }

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
        
        NavigationSplitView {       Sidebar(selection: selection)
        }
        content:
        {
            SampleList(experiment: store.getSelectedExperiment(), store: _store)
                .frame(minWidth: 100, idealWidth: 600)
        }
        detail:
        {
            NavigationSplitView {           //Nested split view
                AnalysisList()                  // sidebar
                    .frame(minWidth: 250, idealWidth: 250)
                }
            detail: {
                if mode == .table        {   tableBuilder     }
                else if mode == .gating  {   GatingView()     }
                else                     {   LayoutPasteboard(mode: mode)   }
            }
        .toolbar {   ReportModePicker(mode: $mode)    }
//            Text("Unused Rotated Axis Name").rotationEffect(Angle(degrees: 90)).opacity(mode == .gating ? 1.0 : 0.0)   }//
         }
    }
}
