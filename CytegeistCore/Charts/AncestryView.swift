//
//  SwiftUIView.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 9/25/24.
//

import SwiftUI
import CytegeistLibrary

public struct AncestryView: View {
    let population:AnalysisNode?
    let height: CGFloat?
    
    public init(_ population: AnalysisNode?, height: CGFloat) {
        self.population = population
        self.height = height
    }
    
    public var body: some View {
        let ancestry = population?.ancestry()
        return Group {
            if let ancestry, ancestry.count > 1 {
                ScrollView(.horizontal) {
                    HStack(spacing: 4) {
                        ForEach(ancestry) { ancestor in
                            //                            @Bindable var ancestor = ancestor
                            if let gate = ancestor.gate, let parent = ancestor.parent {
                                let chartDef = ancestorChartDef(gate)
                                
                                VStack {
                                    Text(parent.name.nonEmpty(" ")) // AM Should the name be for the plotted ancestor, or for the gate
                                    ChartView(population: parent, config: readOnlyBinding(chartDef), editable: false, focusedItem: nil)
                                        .padding(3)
                                        .frame(width: height, height: height)
                                        .background(.black.opacity(0.1))
                                        .cornerRadius(12)
                                }
                            } else {
                            }
                        }
                        Spacer()
                    }
                }
//                .frame(height:height)
            } else {
                VStack {}
                    .frame(height: 0)
            }
        }
    }
    // TODO -- doesnt set graph type
    private func ancestorChartDef(_ gate:AnyGate) -> ChartDef? {
        var chartDef = ChartDef()
        if let xDim = gate.dims.get(index: 0) {
            chartDef.xAxis = ancestorAxisDef(dim: xDim)
        }
        if let yDim = gate.dims.get(index: 1) {
            chartDef.yAxis = ancestorAxisDef(dim: yDim)
        }
        return chartDef
    }
    
    private func ancestorAxisDef(dim:String) -> AxisDef {
        .init(dim:dim, showTickLabels: false, scale: 0.7)
    }
}
