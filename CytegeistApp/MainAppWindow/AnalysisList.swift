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
                } // nog
            } //List
        }  //vstack
    }  // list
    
//    @MainActor
//    func freqOfParentIcon(_ freq: CGFloat) -> PieChartShape {
            //    precondition( {freq > 0 && freq < 1.0} )
//        let twoPi = 2.0 * CGFloat.pi
//        let r = 30.0
//        let center = CGPoint(x: r, y:r)
//        let path = Path { p in
//            p.move(to: center)
//            p.addLine(to: CGPoint(x: r, y:0))
//            p.addArc(center: CGPoint(x: r, y:r), radius: r, startAngle: .radians(0), endAngle: .radians(twoPi * freq), clockwise: true)
//            p.addLine(to: center)
//            p.addArc(center: CGPoint(x: r, y:r), radius: r, startAngle: .radians(0), endAngle: .radians(twoPi), clockwise: true)
//        }.stroke(.green, lineWidth: 2.6)
//        let renderer = ImageRenderer(content: path)
//        
//        if let nsImage = renderer.nsImage{
//            return  nsImage
//        }
//        return NSImage()
//        
//        return FreqOfParentIcon(population: )
//    }
}

public struct AnalysisNodeView: View {
    @Environment(CytegeistCoreAPI.self) var core
    @State var request:APIQuery<StatisticBatch>?
    
    let node:AnalysisNode
    let iconSize = 18.0

    public var body: some View {
        let data = request?.data
        let freqOfParent = data?[.freqOfParent]
        let freqOfTotal = data?[.freqOfTotal]
        
        let population = self.node as? PopulationNode
        let populationRequest = try? population?.createRequest()
        
        
        HStack {
            LoadingOverlay(isLoading: request != nil && request!.isLoading, scale: 0.5) {
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
                    
                    Circle()
                        .stroke(.blue, lineWidth: 1)
                    
                }
            }
            .fixedSize()
            Text(node.name)
                .font(.system(.title3, design: .rounded))
//                .frame(maxWidth: .infinity, maxHeight: 30, alignment: .leading)
            if let freqOfParent, freqOfParent.isFinite{
                Text(freqOfParent.asPercentage())
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .onChange(of: populationRequest, initial: true) {
            request?.dispose()
            request = nil
            if let populationRequest {
                request = core.statistics(populationRequest, "", .freqOfTotal, .freqOfParent)
            }
        }
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
//        p.addLine(to: center + CGPoint(x: r, y:0))
        p.addArc(center: center, radius: r, startAngle: startAngle, endAngle: startAngle - .radians(twoPi * freq), clockwise: true)
        p.addLine(to: center)
        
        p.closeSubpath()
//        p.addArc(center: CGPoint(x: r, y:r), radius: r, startAngle: .radians(0), endAngle: .radians(twoPi), clockwise: true)
        return p
    }
}


//        //where Node: Hashable, Node: Identifiable, Node: CustomStringConvertible
//    
//    struct NodeOutlineGroup<AnalysisNode>: View {
//        let node: AnalysisNode
//        let childKeyPath: KeyPath<AnalysisNode, [AnalysisNode]?>
//        @State var isExpanded: Bool = true
//        
//        var body: some View {
//            if node[keyPath: childKeyPath] != nil {
//                DisclosureGroup(
//                    isExpanded: $isExpanded,
//                    content: {
//                        if isExpanded {
//                            ForEach(node[keyPath: childKeyPath]!) { childNode in
//                                NodeOutlineGroup(node: childNode, childKeyPath: childKeyPath, isExpanded: isExpanded)
//                            }
//                        }
//                    },
//                    label: { Text(node.name) })
//            } else {
//                Text(node.description)
//            }
//        }
//    }


