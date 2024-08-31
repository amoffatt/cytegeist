//
//  AnalysisTree.swift
//  filereader
//
//  Created by Adam Treister on 8/10/24.
//

import Foundation
import SwiftUI
import CytegeistCore



    //-------------------------------------------------------------------------------
struct AnalysisList: View {
    @Environment(Experiment.self) var experiment
    
 
    var body: some View {
//        @Bindable var experiment = experiment
        
        
        VStack {
            if let sample = experiment.focusedSample {
                let tree = sample.getTree()
                list(sample, tree)
            }
            else {
                Text("Select a sample")
            }
        }
    }
    
//    @State var selection:AnalysisNodeSelection = .init()
    
    func list(_ sample:Sample, _ tree:AnalysisNode) -> some View {
        @Bindable var selection = experiment.selectedAnalysisNodes
        
        return VStack {
            Text("Analysis Tree for \(sample.tubeName): selected: \(selection.nodes.debugDescription)").frame(width: 150)
            List(selection: $selection.nodes) {
                OutlineGroup(tree, children: \.children.emptyToNil) {  item in
                    HStack {
                        Image(systemName: "lightbulb")  //item.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 30)
                        Text(item.name)
                            .font(.system(.title3, design: .rounded))
                            .frame(maxWidth: .infinity, maxHeight: 30, alignment: .leading)
                    }
                    .frame(width: 350, height: 30)
                    .draggable(item) {
                        Label(item.name, systemImage: "lightbulb")      // this is the drag image
                            .bold().offset(x: -100)
                            .foregroundStyle(.orange)
                            .frame(minWidth: 350, minHeight: 30)
                    }
                    .tag(item)
                }
            }
        }
    }
}
