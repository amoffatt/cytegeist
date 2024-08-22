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
struct CytegeistApp: SwiftUI.App {

    @State private var appModel = App()
//    @StateObject  var store = Store()
    

    var body: some Scene {
//        WindowGroup {
//            AaronTestContentView()
//                .environment(appModel)
//        }
        
        
        #if os(macOS)
        
        Window("Navigation", id: "nav")
        {
            MainAppView()
                .environment(appModel)
        }
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
