//
//  AnalysisTree.swift
//  filereader
//
//  Created by Adam Treister on 8/10/24.
//

import Foundation
import SwiftUI
import CytegeistCore
import CytegeistLibrary

 //-------------------------------------------------------------------------------
struct AnalysisList: View {
    @Environment(Experiment.self) var experiment
    
    var body: some View {
        VStack {
            if let sample = experiment.focusedSample {
                list(sample, sample.getTree())
            }
            else { Text("Select a sample")  }
        }
    }
    
    func list(_ sample:Sample, _ tree:AnalysisNode) -> some View {
        @Bindable var selection = experiment.selectedAnalysisNodes
        
        return VStack {
            Text("Analysis for \(sample.tubeName): selected: \(selection.nodes.count)").frame(width: 150)
            List(selection: $selection.nodes) {
                OutlineGroup(tree, children: \.children.emptyToNil) {  item in
                        //            NodeOutlineGroup(tree, children: \.children.emptyToNil, isExpanded: true) {  item in
                    
                    AnalysisNodeView(node:item)
                        .frame(width: 350, height: 30)
                        .draggable(item) {
                            Label(item.name, systemImage: "lightbulb")      // this is the drag image
                                .bold().offset(x: -100)
                                .foregroundStyle(.orange)
                                .frame(minWidth: 350, minHeight: 30)
                        }
                        .tag(item)
                }
            } //List
        }  //vstack
    }  // list
    
    
        //-------------------------------------------------------------------------------
    public struct AnalysisNodeView: View {
        @Environment(CytegeistCoreAPI.self) var core
        @State var query = APIQuery<StatisticBatch>()
        
        let node:AnalysisNode
        let iconSize = 18.0
        
        public var body: some View {
            let data = query.data
            let freqOfParent = data?[.freqOfParent]
            let freqOfTotal = data?[.freqOfTotal]
            let population = self.node as? AnalysisNode
            let populationRequest = try? population?.createRequest()
            
            HStack {
                    //            LoadingOverlay(isLoading: query.isLoading, scale: 0.5) {
                ZStack {
                    ZStack {
                        if let freqOfParent, let freqOfTotal {
                            PieChartShape(freq: freqOfParent)
                                .fill(.blue)
                            PieChartShape(freq: freqOfTotal)
                                .fill(.green)
                        }
                    }
                    .frame(width:iconSize, height:iconSize)
                    .padding(3)
                    
                    Circle().stroke(.blue, lineWidth: 1)
                    
                }.fixedSize()
                Text(node.name)
                    .font(.system(.title3, design: .rounded))
                    //                .frame(maxWidth: .infinity, maxHeight: 30, alignment: .leading)
                if let freqOfParent, freqOfParent.isFinite{
                    Text(freqOfParent.asPercentage())
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Spacer()
                CProgressView(visible: query.isLoading)
                    .scaleEffect(0.6)
                
            }
            .frame(maxWidth: .infinity)
            .update(query:query,
                    onChangeOf: populationRequest,
                    with:core.statistics(populationRequest, "", .freqOfTotal, .freqOfParent)
            )
        }
    }
    
    
    public struct PieChartShape : Shape {
        public let freq: Double
        public func path(in rect: CGRect) -> Path {
            var p = Path()
            let center = rect.center
            let r = rect.width / 2
            let startAngle = Angle.radians(-CGFloat.pi/2)
            p.move(to: center)
            p.addArc(center: center, radius: r, startAngle: startAngle, endAngle: startAngle - .radians(twoPi * freq), clockwise: true)
            p.addLine(to: center)
            p.closeSubpath()
            return p
        }
    }
}
