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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        #if os(macOS)
        Window("Pair Charts", id: "pair-charts") {
            PairChartsPreview()
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
