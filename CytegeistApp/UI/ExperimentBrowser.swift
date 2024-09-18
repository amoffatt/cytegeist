//
//  ExperimentBrowser.swift
//  CytegeistApp
//
//  Created by Adam Treister on 9/17/24.
//

import Foundation
import SwiftUI




struct ExperimentBrowser : View {
    
    @Environment(App.self) var app: App
    
    
    var body: some View {
        @Bindable var app = app
        
        NavigationSplitView {
            BrowserSidebar()
        }
    content:
        {
            HSplitView {
                PanelA()
                    .frame(minWidth: 100, idealWidth: 600)
                
                PanelB()
                    .frame(minWidth: 250, idealWidth: 600, maxWidth: .infinity, maxHeight: .infinity)
                    .fillAvailableSpace()
                
                VStack {
                    Text("No experiment selected...")
                    Button("Create New Experiment") {
                        app.createNewExperiment()
                    }
                }
            }
                //            .frame(minWidth: 250, idealWidth: 800, maxWidth: .infinity)
                //            .fillAvailableSpace()
            .navigationSplitViewColumnWidth(min: 600, ideal: 1600, max: .infinity)
            
        }
    detail: {
        VStack {
            TableBuilder()
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
