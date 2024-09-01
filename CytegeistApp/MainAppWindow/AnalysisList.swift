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
                NodeOutlineGroup(tree, children: \.children.emptyToNil) {  item in
                    HStack {
                        Image(systemName: "lightbulb")// nsImage: freqOfParentIcon(item.freqOfParent()))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 30)
                        Text(" \(item.name) :  \(item.freqOfParent())" )
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
                } // nog
            } //List
        }  //vstack
    }  // list
    @MainActor
    func freqOfParentIcon(_ freq: CGFloat)async -> NSImage   {
            //    precondition( {freq > 0 && freq < 1.0} )
        let twoPi = 2.0 * CGFloat.pi
        let r = 30.0
        let path = Path { p in
            p.addArc(center: CGPoint(x: r, y:r), radius: r, startAngle: .radians(0), endAngle: .radians(twoPi * freq), clockwise: true)
            p.addArc(center: CGPoint(x: r, y:r), radius: r, startAngle: .radians(0), endAngle: .radians(twoPi), clockwise: true)
        }.stroke(.green, lineWidth: 2.6)
        let renderer = ImageRenderer(content: path)
        
        if let nsImage = renderer.nsImage{
            return  nsImage
        }
        return NSImage()
    }
    
        //where Node: Hashable, Node: Identifiable, Node: CustomStringConvertible
    
    struct NodeOutlineGroup<AnalysisNode>: View {
        let node: AnalysisNode
        let childKeyPath: KeyPath<AnalysisNode, [AnalysisNode]?>
        @State var isExpanded: Bool = true
        
        var body: some View {
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
                    label: { Text(node.name) })
            } else {
                Text(node.description)
            }
        }
    }
}

