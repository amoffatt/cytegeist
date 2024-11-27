//
//  CytegeistApp.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/13/24.
//

import SwiftUI
import CytegeistCore
//import SwiftData

@main
@MainActor
struct CytegeistApp: SwiftUI.App {

    @State private var appModel = App()

    @FocusedValue(\.analysisNode) var focusedAnalysisNode
       
   
    var body: some Scene {
        #if os(macOS)
            Window("Navigation", id: "nav")
            {
                ExperimentView().environment(appModel)
//                    .modelContainer(for:  [Experiment.self, Sample.self], isUndoEnabled: true)
            }

            .commands {
                if let focusedAnalysisNode,
                   let focusedAnalysisNode {
                    
                    CommandMenu("Chart") {
                        Button("Toggle Smoothing") {
                            let smoothing = focusedAnalysisNode.chartDef.smoothing
                            focusedAnalysisNode.chartDef.smoothing = smoothing == .off ? .low : .off
                        }
                        Button("Toggle Contours") {
                            let contours = focusedAnalysisNode.chartDef.contours
                            focusedAnalysisNode.chartDef.contours = contours ? false : true
                        }
                    }
                 }
            }
             
            Window("Pair Charts", id: "pair-charts") {
                PairChartsPreview()
                    .environment(BatchContext.empty)
            }
        
        WindowGroup(id: "sample-inspector", for: ExperimentSamplePair.self) { $sample in
            if let sample = $sample.wrappedValue, 
                let ref = sample.sample.ref {
                SampleInspectorView(sample.experiment, sample:ref)
            }
        }
        
            
        Window("Experiment Browser", id: "browse")
        {
            ExperimentBrowser().environment(appModel)
//                .environmentObject(core)
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
