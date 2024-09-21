//
//  ChartAxis.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 8/22/24.
//

import SwiftUI
import CytegeistLibrary

public struct ChartAxisView: View {
    var dim:Binding<String>
    let normalizer: AxisNormalizer?
    var sampleMeta: FCSMetadata?

    public var body: some View {
//        let label = sampleMeta?.parameter(named: dim.wrappedValue)?.name ?? "<None selected>"
        let availableParameters = sampleMeta?.parameters ?? []
        
        GeometryReader { proxy in
            VStack {
                if let normalizer = normalizer {
                    ticks(proxy, normalizer)
                }
                Picker("", selection: dim) {
                    Text("<None>")
                        .tag("")
                    ForEach(availableParameters, id: \.name) { p in
                        Text(p.displayName)
                            .tag(p.name)
                    }.frame(maxWidth: 50, maxHeight: 200)
                }
                .pickerStyle(.menu)
            }
        }
    }
    
    func ticks(_ proxy: GeometryProxy, _ normalizer:AxisNormalizer) -> some View {
        let ticks = normalizer.tickMarks(4)
        let size = proxy.size
        return ZStack(alignment: .topLeading) {
            ForEach(ticks) { majorTick in
                let x = size.width * CGFloat(majorTick.normalizedValue)
                Rectangle()
                    .frame(width: 2, height: 10)
                    .position(x: x, y: 5)
                
                Text(majorTick.label)
                    .position(x: x, y: 20)

            }
            .frame(width: size.width, height: 50)
        }
    }
}

//#Preview {
//    ChartAxisView(
//        label:"My Parameter",
//        normalizer: .linear(min: -2.1, max: 520)
//    )
//}
