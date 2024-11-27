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
            else { Text("No Sample Selected").opacity(0.2)  }
        }
    }
    
    func list(_ sample:Sample, _ tree:AnalysisNode) -> some View {
        @Bindable var selection = experiment.selectedAnalysisNodes
        
        return VStack {
            HStack {
                Text("For \(sample.tubeName): selected: \(selection.nodes.count)") //.frame(width: 150)
                Spacer()
                Button("<< Copy", action: experiment.copyToGroup)
            }
            List(selection: $selection.nodes) {
                NodeOutlineGroup<AnalysisNode>(node: tree, childKeyPath: \.children.emptyToNil, isExpanded: true)
//                OutlineGroup(tree, children: \.children.emptyToNil) {  item in
                        //            NodeOutlineGroup(tree, children: \.children.emptyToNil, isExpanded: true) {  item in
//                    
//                    AnalysisNodeView(node:item)
//                        .frame(width: 350, height: 30)
//                        .draggable(item) {
//                            Label(item.name, systemImage: "lightbulb")      // this is the drag image
//                                .bold().offset(x: -100)
//                                .foregroundStyle(.orange)
//                                .frame(minWidth: 350, minHeight: 30)
//                        }
//                        .tag(item)
//                }
            } //List
        }  //vstack
    }  // list
    
        //-------------------------------------------------------------------------------
    
    struct NodeOutlineGroup<Node>: View where Node: Hashable, Node: Identifiable, Node: CustomStringConvertible {
        let node: Node
        let childKeyPath: KeyPath<Node, [Node]?>
        @State var isExpanded: Bool = true
        
        var body: some View {
            if let anode = node as? AnalysisNode {
                if node[keyPath: childKeyPath] != nil {
                    DisclosureGroup(
                        isExpanded: $isExpanded,
                        content: {
                            if isExpanded {
                                ForEach(node[keyPath: childKeyPath]!) { childNode in
                                    NodeOutlineGroup(node: childNode, childKeyPath: childKeyPath, isExpanded: isExpanded)
                                }
                            }
                        },
                        label:  {
                            AnalysisNodeView(node: anode)
                                .frame(width: 350, height: 30)
                                .draggable(anode) {
                                    Label(anode.name, systemImage: "lightbulb")      // this is the drag image
                                        .bold().offset(x: -100)
                                        .foregroundStyle(.orange)
                                        .frame(minWidth: 350, minHeight: 30)
                                }
                            .tag(anode) }
                    )
                } else {
                    AnalysisNodeView(node: anode)
                        .frame(width: 350, height: 30)
                        .draggable(anode) {
                                    Label(anode.name, systemImage: "lightbulb")      // this is the drag image
                                        .bold().offset(x: -100)
                                        .foregroundStyle(.orange)
                                        .frame(minWidth: 350, minHeight: 30)
                                }
                                .tag(anode)
                        }
            }  //vstack
        }  // list
    }

    
//-------------------------------------------------------------------------------
// one line in the list:

    public struct AnalysisNodeView: View {
        @Environment(CytegeistCoreAPI.self) var core
        @Environment(BatchContext.self) var batchContext
        @State var query = APIQuery<StatisticBatch>()
        
        let node:AnalysisNode
        
        public var body: some View {
            let iconSize = 16.0
            let data = query.data
            let freqOfParent = data?[.freqOfParent]
            let freqOfTotal = data?[.freqOfTotal]
            let populationRequest = try? node.createRequest(batchContext)
            
            HStack {
                ZStack {
                    ZStack {
                        if let freqOfParent, let freqOfTotal {
                            PieChartShape(freq: freqOfParent).fill(.blue)
                            PieChartShape(freq: freqOfTotal).fill(.green)
                        }
                    }
                    .frame(width:iconSize, height:iconSize)
                    .padding(3)
                    
                    Circle().stroke(.blue, lineWidth: 1)
                    
                }.fixedSize()
                let name = node.name.isEmpty ? "All Cells": node.name
                Text(name)
                    .font(.system(.title3, design: .rounded))
                    //                .frame(maxWidth: .infinity, maxHeight: 30, alignment: .leading)
                Spacer()
                if let freqOfParent, freqOfParent.isFinite{
                    Text(freqOfParent.asPercentage())
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Spacer()
                CProgressView(visible: query.isLoading) .scaleEffect(0.3)
                
            }
            .frame(maxWidth: .infinity)
            .update(query:query,
                    onChangeOf: populationRequest,
                    with:core.statistics(populationRequest, "", .freqOfTotal, .freqOfParent)
            )
        }
        
        struct PieChartShape : Shape {
            let freq: Double
            func path(in rect: CGRect) -> Path {
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
}

