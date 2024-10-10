//
//  CytegeistCoreViewTestsApp.swift
//  CytegeistCoreViewTests
//
//  Created by Aaron Moffatt on 9/24/24.
//

import SwiftUI
import CytegeistCore

@main
struct CytegeistViewTestsApp: App {
    @State var core: CytegeistCoreAPI = CytegeistCoreAPI()
    
    var body: some Scene {
        let size = Chart3DView.VolumeSize
//        WindowGroup {
//            ContentView()
//        }
        
        WindowGroup {
            Chart3DViewTest()
        }
        .windowStyle(.volumetric)
        .defaultSize(width: size.width, height: size.height, depth: size.depth, in: .meters)
        .environment(core)
    }
}
