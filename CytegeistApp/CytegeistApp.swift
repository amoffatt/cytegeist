//
//  CytegeistApp.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/13/24.
//

import SwiftUI
import CytegeistCore

@main
@MainActor
struct CytegeistApp: App {

    @State private var appModel = AppModel()
//    @StateObject  var store = Store()
    

    var body: some Scene {
//        WindowGroup {
//            AaronTestContentView()
//                .environment(appModel)
//        }
        
        
        
        #if os(macOS)
        
//        Window("Navigation", id: "nav")
//        {
//            MainView(selectedExperimentID: $store.selectedExperiment)
//                .environmentObject(store)
//        }
//        Settings {
//            SettingsView()
//                .environmentObject(store)
//        }
        
        Window("Pair Charts", id: "pair-charts") {
            PairChartsPreview()
        }
        
        Window("SaveOpenView", id: "SaveOpen")
        {
            SaveOpenView()
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
