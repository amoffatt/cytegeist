//
//  CytegeistApp.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/13/24.
//

import SwiftUI
import CytegeistCore
import SwiftData

@main
@MainActor
struct CytegeistApp: SwiftUI.App {

    @State private var appModel = App()
//    @StateObject  var store = Store()
    @Environment(\.undoManager) var undoManager

    var body: some Scene {
//            AaronTestContentView()
//                .environment(appModel)
//        }
        
        
        #if os(macOS)
            Window("Navigation", id: "nav")
            {
                ExperimentView()
                    .environment(appModel)
//                     .modelContainer(for:  Experiment.self, isUndoEnabled: true)
            }
                //        Settings {
                //            SettingsView()
                //                .environmentObject(store)
                //        }
            
            Window("Pair Charts", id: "pair-charts") {
                PairChartsPreview()
            }
            
//        Window("SaveOpenView", id: "SaveOpen")
//        {
//            SaveOpenView()
//        }
//        
        Window("Experiment Browser", id: "browse")
        {
            ExperimentBrowser()
                .environment(appModel)
        }
        

        #endif

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
