//
//  NavView.swift
//  filereader
//
//  Created by Adam Treister on 7/28/24.
//

import SwiftUI
import UniformTypeIdentifiers
import CytegeistCore


    // switch between table and gallery views in the sampleList
enum ViewMode: String, CaseIterable, Identifiable {
    var id: Self { self }
    case gallery
    case table
}

    // switch between gating, table and layout views in the rightmost view
enum ReportMode: String, CaseIterable, Identifiable {
    var id: Self { self }
    case gating
    case table
    case layout
}



struct MainAppView : View {
   
    @Environment(App.self) var app: App

    var mode:ReportMode { app.reportMode }
    
//    @State private var path = [Int]()
        //----------------------------------------------------------------------------------
    

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
                        .environment(selected.core)
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
                    case .table:  TableBuilder()
                    case .gating: gatingBuilder(experiment)
                    case .layout: LayoutBuilder()
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
//===================================================================
    
    func gatingBuilder(_ exp: Experiment) -> some View {
        VStack {
            if let node = exp.focusedAnalysisNode {
                GatingView(population:node)
            }
        }
    }
//===================================================================

    }
