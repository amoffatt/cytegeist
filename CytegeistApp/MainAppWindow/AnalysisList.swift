//
//  AnalysisTree.swift
//  filereader
//
//  Created by Adam Treister on 8/10/24.
//

import SwiftUI


    //-------------------------------------------------------------------------------
struct AnalysisList: View {
 
    @State var selection = Set<AnalysisNode.ID>()
    var body: some View {
        VStack {
            
            Text("Analysis Tree").frame(width: 150)
            List(selection: $selection) {
                OutlineGroup(sections, children: \.children) {  item in
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
                }
            }
        }
    }
}
