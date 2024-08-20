//
//  ChartView.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/27/24.
//

import SwiftUI

public struct ChartView: View {
//    todofileRef() //?
//    todoFileQueryAPI() // ?
    let core: CytegeistCoreAPI
    @State var sample: SampleRef
    @State var parameterNames: Tuple2<String>
    
    public init(_ core: CytegeistCoreAPI, sample: SampleRef, parameterNames: Tuple2<String>) {
        self.core = core
        self.sample = sample
        self.parameterNames = parameterNames
    }
    
    public var body: some View {
        VStack {
            HistogramView(query: core.histogram(.init(population: .init(sample), axisNames: .init(parameterNames.x))))
//            Histogram2DView(data: core.histogram2D(sampleRef: sample, parameterNames: parameterNames))
//            Selector()
        }
        .frame(width: 400, height: 400)
    }
}

#Preview {
    let core = CytegeistCoreAPI()
//    return VStack { Text("Test world")}
    let sample = SampleRef(url: DemoData.facsDivaSample0!)
    let parameters = Tuple2("FSC-A", "PacificBlue-A")
//
    return ChartView(core, sample: sample, parameterNames: parameters)
}
