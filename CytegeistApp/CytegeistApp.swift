//
//  CytegeistApp.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/13/24.
//

import SwiftUI
import CytegeistCore
import CytegeistLibrary
import SwiftData

@main
@MainActor
struct CytegeistApp: SwiftUI.App {

    @State private var appModel = App()
    @FocusedValue(\.analysisNode) var focusedAnalysisNode

    var body: some Scene {        
        #if os(macOS)
            Window("Experiment", id: "nav")
            {
                ExperimentView().environment(appModel)
//                     .modelContainer(for:  Experiment.self, isUndoEnabled: true)
            }
            .commands {
                if let focusedAnalysisNode,
                   let focusedAnalysisNode {
                    
                    CommandMenu("Chart") {
                        Button("Toggle Smoothing") {
                            let smoothing = focusedAnalysisNode.graphDef.smoothing
                            focusedAnalysisNode.graphDef.smoothing = smoothing == .off ? .low : .off
                        }
                        Button("Toggle Contours") {
                            let contours = focusedAnalysisNode.graphDef.contours
                            focusedAnalysisNode.graphDef.contours = contours ? false : true
                        }
                    }
                }
            }
             
            Window("Pair Charts", id: "pair-charts") {
                PairChartsPreview()
            }
            
        Window("Experiment Browser", id: "browse")
        {
            ExperimentBrowser().environment(appModel)
        }
        #endif

//       Window("SaveOpenView", id: "SaveOpen") {   SaveOpenView()  }
//        Settings {    SettingsView().environmentObject(store)    }

            //        ImmersiveSpace(id: appModel.immersiveSpaceID) {
//            ImmersiveView()
//                .environment(appModel)
//                .onAppear {
//                    appModel.immersiveSpaceState = .open
//                }
//                .onDisappear {
//                    appModel.immersiveSpaceState = .closed
//                }
//        }
//        .immersionStyle(selection: .constant(.mixed), in: .mixed)
     }
}
