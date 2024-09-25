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
//        WindowGroup {
//            ContentView()
//        }
        
        WindowGroup {
            Chart3DViewTest()
        }
        .windowStyle(.volumetric)
        .environment(core)
    }
}
