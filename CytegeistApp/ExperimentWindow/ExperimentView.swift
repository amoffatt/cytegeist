//
//  NavView.swift
//  filereader
//
//  Created by Adam Treister on 7/28/24.
//

import SwiftUI
import UniformTypeIdentifiers
import CytegeistCore
import CytegeistLibrary


    // switch between table and gallery views in the sampleList
enum SampleListMode: String, CaseIterable, Identifiable, Codable {
    var id: Self { self }
    case gallery
    case table
    case compact
}

    // switch between gating, table and layout views in the rightmost view
enum ReportMode: String, CaseIterable, Identifiable, Codable {
    var id: Self { self }
    case gating
    case table
    case layout
}

//----------------------------------------------------------------------------------


struct ExperimentView : View {
   
//    var mode:ReportMode { app.reportMode }
    
//    @State private var path = [Int]()
    @State var sampleMinWidth: CGFloat  = 12
    @State  var sampleIdealWidth: CGFloat  = 800
    @State var analysisMinWidth: CGFloat  = 12
    @State  var analysisIdealWidth: CGFloat  = 800
    
    let experiment: Experiment


    var body: some View {
        
        // AM Note: If we need to support Pre-macOS13, see https://developer.apple.com/documentation/swiftui/migrating-to-new-navigation-types
        NavigationSplitView {
            Sidebar()
        }
        content: {
            Group {
                HSplitView {
                    SampleList(experiment: experiment)
                        .frame(minWidth: sampleMinWidth, idealWidth: sampleIdealWidth, maxWidth: .infinity, maxHeight: .infinity)
                    
                    AnalysisList()
                        .frame(minWidth: analysisMinWidth, idealWidth: analysisIdealWidth, maxWidth: .infinity, maxHeight: .infinity)
                    //                                .fillAvailableSpace()
                }
                .environment(experiment)
                .environment(experiment.core)
				.environment(selected.defaultBatchContext)
                .onChange(of: experiment.selectedSamples) {
                    experiment.clearAnalysisNodeSelection()
                }
            }
            .frame(minWidth: 150, idealWidth: 800, maxWidth: .infinity)
            .fillAvailableSpace()
            .navigationSplitViewColumnWidth(min: 72, ideal: 1600, max: .infinity)
            
        }
        detail: {
                VStack {        // AM: VStack leads to better compile error messages than Group when the below code breaks (!?)
                    switch experiment.reportMode {
              
                    case .table:  TableBuilder()
                    case .gating:  VStack {
                                        if let node = experiment.focusedAnalysisNode {
                                            GatingView(population:node)
                                        }
                                    }
                    case .layout: LayoutBuilder()
                    }
                    
                }
                .environment(experiment)
                .environment(experiment.core)
                .environment(experiment.defaultBatchContext)
                .navigationSplitViewColumnWidth(min: 12,  ideal: 1200, max: .infinity)
                .toolbar {
                    let binding = Binding(
                        get: { experiment.reportMode },
                        set: { experiment.reportMode = $0 }
                    )
                    ReportModePicker(mode: binding)
                }
         }
    }
}
    
    //===================================================================

  
