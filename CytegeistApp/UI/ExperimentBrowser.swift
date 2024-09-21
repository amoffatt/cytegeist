//
//  ExperimentBrowser.swift
//  CytegeistApp
//
//  Created by Adam Treister on 9/17/24.
//

import Foundation
import SwiftUI




struct ExperimentBrowser : View {
    
//    @Environment(App.self) var app: App
    
    
    var body: some View {
//        @Bindable var app = app
        
        NavigationSplitView {
            BrowserSidebar()
        }
    content:
        {
            TableBuilder()
                .navigationSplitViewColumnWidth(min: 600, ideal: 1600, max: .infinity)
        }
    detail: {
        VStack {
            PanelA()
         }
        .navigationSplitViewColumnWidth(min: 300, ideal: 1200, max: .infinity)
        
        }
    }
    
        //
    struct BrowserSidebar :  View {
        
        var body : some View   {
            Text("BrowserSidebar")
        }
        
    }
    
    struct PanelA :  View {
        
        var body : some View
        {
            Text("PanelA")
        }
        
    }
    struct PanelB :  View {
        
        var body : some View
        {
            Text("PanelB")
        }
        
    }
}
